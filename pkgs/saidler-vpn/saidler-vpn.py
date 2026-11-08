#!@python@
"""Saidler VPN launcher and vpnc's email-code helper. Secrets stay outside Nix."""
import configparser
import contextlib
import email
import email.policy
import email.utils
import fcntl
import imaplib
import json
import os
import pathlib
import pwd
import re
import signal
import ssl
import stat
import subprocess
import sys
import tempfile
import termios
import time

VPNC = "@vpnc@"
PROFILE_FILE = pathlib.Path("/etc/vpnc/saidler.conf")
MAIL_TIMEOUT = 60
STATE_ENV = "SAIDLER_VPN_MAIL_STATE"


def read_password(path):
    if stat.S_IMODE(path.stat().st_mode) & 0o077:
        raise ValueError(f"Password file must have permissions 600: {path}")
    password = path.read_text().removesuffix("\n").removesuffix("\r")
    if not password or any(c in password for c in "\r\n\0"):
        raise ValueError(f"Password file must contain one nonempty line: {path}")
    return password


def config_dir():
    # pkexec names the launching user; their settings stay in their home.
    uid = os.environ.get("PKEXEC_UID", "")
    if not uid.isdigit():
        raise ValueError("Start this VPN through the Saidler VPN launcher.")
    return pathlib.Path(pwd.getpwuid(int(uid)).pw_dir) / ".config" / "saidler-vpn"


def mail_settings(directory):
    path = directory / "mail.ini"
    parser = configparser.ConfigParser(interpolation=None)
    try:
        if not parser.read(path):
            raise ValueError(f"Missing mail settings: {path}")
        section = parser["mail"]
        return {"host": section["host"], "user": section["user"], "sender": section["sender"].lower(),
                "password_file": str(directory / "mail-password")}
    except configparser.Error as error:
        raise ValueError(f"Invalid mail settings in {path}: {error}") from error


@contextlib.contextmanager
def mailbox(mail):
    client = imaplib.IMAP4_SSL(mail["host"], 993, ssl_context=ssl.create_default_context(), timeout=8)
    try:
        client.login(mail["user"], read_password(pathlib.Path(mail["password_file"])))
        yield client
    finally:
        with contextlib.suppress(Exception):
            client.logout()


def mailbox_state(client):
    status, data = client.status("INBOX", "(UIDVALIDITY UIDNEXT)")
    if status != "OK":
        raise ValueError("Cannot inspect inbox.")
    fields = dict(re.findall(rb"(UIDVALIDITY|UIDNEXT)\s+(\d+)", b" ".join(data)))
    return {"uidvalidity": int(fields[b"UIDVALIDITY"]), "uidnext": int(fields[b"UIDNEXT"])}


def extract_code(raw, started_at, sender_address):
    message = email.message_from_bytes(raw, policy=email.policy.default)
    sender = email.utils.getaddresses(message.get_all("From", []))
    if len(sender) != 1 or sender[0][1].lower() != sender_address:
        return None
    subject = re.fullmatch(r"AuthCode:\s*([0-9]{6})", str(message.get("Subject", "")).strip())
    if not subject:
        return None
    try:
        date = email.utils.parsedate_to_datetime(str(message.get("Date", "")))
        if date.tzinfo is None or not started_at - 5 <= date.timestamp() <= time.time() + 60:
            return None
    except (TypeError, ValueError, OverflowError):
        return None
    for part in message.walk():
        if part.get_content_type() != "text/plain" or part.get_content_disposition() == "attachment":
            continue
        try:
            body = part.get_content()
        except (LookupError, UnicodeError, ValueError):
            continue
        match = re.search(r"Your authentication token code is\s+([0-9]{6})\b", body)
        if match and match[1] == subject[1]:
            return match[1]
    return None


def new_uids(data, minimum):
    return sorted({int(uid) for uid in b" ".join(data).split() if uid.isdigit() and int(uid) >= minimum}, reverse=True)


def retrieve_code(state):
    deadline = time.monotonic() + MAIL_TIMEOUT
    checked = set()
    with mailbox(state) as client:
        # Writable selection is intentional: mark only the chosen code email read.
        if client.select("INBOX")[0] != "OK":
            raise ValueError("Cannot select inbox.")
        while time.monotonic() < deadline:
            if mailbox_state(client)["uidvalidity"] != state["uidvalidity"]:
                raise ValueError("Inbox identifiers changed; refuse stale messages.")
            status, data = client.uid("search", None, "UID", f'{state["uidnext"]}:*', "FROM", f'"{state["sender"]}"')
            if status != "OK":
                raise ValueError("Cannot search inbox.")
            for uid in new_uids(data, state["uidnext"]):
                if uid in checked:
                    continue
                checked.add(uid)
                status, data = client.uid("fetch", str(uid), "(BODY.PEEK[])")
                if status != "OK":
                    continue
                raw = next((part[1] for part in data if isinstance(part, tuple) and isinstance(part[1], bytes)), None)
                if raw is None:
                    continue
                code = extract_code(raw, state["started_at"], state["sender"])
                if code:
                    if client.uid("store", str(uid), "+FLAGS.SILENT", r"(\Seen)")[0] != "OK":
                        print("Code retrieved, but the email could not be marked read.", file=sys.stderr)
                    return code
            time.sleep(2)
    raise TimeoutError("No new matching code email arrived.")


def manual_response(prompt):
    # Read inherited terminal stdin: the VPN runs in a separate session.
    fd = sys.stdin.fileno()
    settings = termios.tcgetattr(fd) if os.isatty(fd) else None
    try:
        if settings is not None:
            hidden = settings.copy()
            hidden[3] &= ~termios.ECHO
            termios.tcsetattr(fd, termios.TCSANOW, hidden)
        print(prompt, end="", file=sys.stderr, flush=True)
        response = sys.stdin.readline()
        if not response:
            raise EOFError("No response entered.")
        return response.rstrip("\r\n")
    finally:
        if settings is not None:
            termios.tcsetattr(fd, termios.TCSANOW, settings)
        print(file=sys.stderr)


def otp_helper(prompt):
    state_path = os.environ.get(STATE_ENV)
    if prompt.startswith("Passcode for VPN ") and state_path:
        try:
            state = json.loads(pathlib.Path(state_path).read_text())
            print("Waiting for your verification email…", file=sys.stderr, flush=True)
            code = retrieve_code(state)
        except (OSError, ValueError, KeyError, imaplib.IMAP4.error):
            print("Automatic code retrieval unavailable. Enter the email code below.", file=sys.stderr)
        else:
            print("Verification code received; connecting…", file=sys.stderr, flush=True)
            # stdout is a private pipe to vpnc, never the terminal.
            print(code, flush=True)
            return 0
    print(manual_response("Email code: " if prompt.startswith("Passcode for VPN ") else prompt), flush=True)
    return 0


def run_vpn():
    if os.geteuid() != 0:
        sys.exit("Start this VPN through the Saidler VPN launcher.")
    lock = open("/run/saidler-vpn.lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        sys.exit("Saidler VPN is already running.")
    settings = config_dir()
    password = read_password(settings / "password")
    profile = "\n".join(line for line in PROFILE_FILE.read_text().splitlines()
                        if not line.startswith(("Xauth interactive", "Xauth password", "Password helper")))
    child = None
    stopping = False

    def stop(signum, frame):
        nonlocal stopping
        stopping = True
        if child is None:
            raise KeyboardInterrupt
        if child.poll() is None:
            with contextlib.suppress(ProcessLookupError):
                os.killpg(child.pid, signal.SIGINT)

    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, stop)
    os.umask(0o077)
    with tempfile.TemporaryDirectory(prefix="saidler-vpn-", dir="/run") as directory:
        runtime_config = pathlib.Path(directory) / "vpn.conf"
        runtime_config.write_text(profile + "\nXauth password " + password + "\n")
        del password
        environment = os.environ.copy()
        environment.pop(STATE_ENV, None)
        print("Connecting to Saidler VPN. Ctrl+C disconnects and closes this window.", flush=True)
        try:
            mail = mail_settings(settings)
            with mailbox(mail) as client:
                state = mailbox_state(client) | mail
            state["started_at"] = time.time()
            state_path = pathlib.Path(directory) / "mail-state.json"
            state_path.write_text(json.dumps(state))
            environment[STATE_ENV] = str(state_path)
        except (OSError, ValueError, KeyError, imaplib.IMAP4.error):
            print("Mail access unavailable; enter the email code when prompted.", flush=True)
        child = subprocess.Popen([VPNC, str(runtime_config), "--id", "", "--no-detach",
                                  "--password-helper", str(pathlib.Path(__file__).resolve())],
                                 start_new_session=True, env=environment)
        if stopping:
            stop(signal.SIGINT, None)
        result = child.wait()
        return 0 if stopping else result


if __name__ == "__main__":
    try:
        sys.exit(otp_helper(sys.argv[1]) if len(sys.argv) > 1 else run_vpn())
    except KeyboardInterrupt:
        sys.exit(0)
    except (OSError, ValueError, EOFError) as error:
        print(f"Saidler VPN: {error}", file=sys.stderr)
        sys.exit(1)
