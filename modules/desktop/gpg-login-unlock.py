"""Restore GPG/SSH passphrases from KWallet without logging or saving plaintext."""

import argparse
import socket
import subprocess
from urllib.parse import quote, quote_from_bytes, unquote_to_bytes


def run(*args, **kwargs):
    return subprocess.run(args, capture_output=True, **kwargs)


class Agent:
    def __init__(self):
        path = run("gpgconf", "--list-dirs", "agent-socket", check=True)
        self.socket = socket.socket(socket.AF_UNIX)
        self.socket.connect(path.stdout.decode().strip())
        self.stream = self.socket.makefile("rwb", buffering=0)
        self.password = None
        self.reply()

    def reply(self):
        data, status = bytearray(), []
        while True:
            line = self.stream.readline().rstrip(b"\r\n")
            if line == b"OK" or line.startswith(b"OK "):
                return bytes(data), status
            if not line or line.startswith(b"ERR "):
                raise RuntimeError("GPG agent rejected the request or it was cancelled")
            if line.startswith(b"D "):
                data.extend(unquote_to_bytes(line[2:]))
            elif line.startswith(b"S "):
                status.append(line[2:].decode())
            elif line.startswith(b"INQUIRE "):
                if line == b"INQUIRE PASSPHRASE" and self.password is not None:
                    self.stream.write(b"D " + quote_from_bytes(
                        self.password, safe="").encode() + b"\nEND\n")
                else:
                    self.stream.write(b"CAN\n")

    def command(self, command):
        self.stream.write(command.encode() + b"\n")
        return self.reply()

    def close(self):
        self.stream.close()
        self.socket.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--setup", action="store_true",
                        help="ask for and verify each key passphrase, then save in KWallet")
    args = parser.parse_args()
    run("gpgconf", "--launch", "gpg-agent", check=True)
    agent = Agent()
    try:
        _, statuses = agent.command("KEYINFO --list --with-ssh")
        count = 0
        for status in statuses:
            fields = status.split()
            if (len(fields) < 7 or fields[0] != "KEYINFO"
                    or fields[2] != "D" or fields[6] != "P"):
                continue
            grip = fields[1]
            password = None
            if args.setup:
                # Ask through the native dialog, then verify before saving.
                # --verify never changes the key or its passphrase.
                desc = quote(f"Unlock GPG/SSH key {grip[-8:]} for automatic login", safe="")
                password, _ = agent.command(
                    f"GET_PASSPHRASE --data X X Passphrase: {desc}")
                try:
                    agent.password = password
                    agent.command("OPTION pinentry-mode=loopback")
                    agent.command(f"PASSWD --verify {grip}")
                finally:
                    agent.password = None
                    agent.command("OPTION pinentry-mode=ask")
                # Use pinentry's standard schema, also allowing native fallback
                # after an agent restart or manual cache clear.
                prefixes = ["n/"]
                if len(fields) > 9 and "S" in fields[9]:
                    prefixes.append("s/")
                for prefix in prefixes:
                    run("secret-tool", "store", "--label",
                        f"GnuPG: {prefix}{grip}",
                        "xdg:schema", "org.gnupg.Passphrase",
                        "stored-by", "GnuPG Pinentry", "keygrip", prefix + grip,
                        input=password + b"\n", check=True)
            else:
                for prefix in ("n/", "s/"):
                    result = run("secret-tool", "lookup",
                                 "xdg:schema", "org.gnupg.Passphrase",
                                 "keygrip", prefix + grip)
                    if result.returncode == 0:
                        password = result.stdout.removesuffix(b"\n")
                        break
            if password is not None:
                run("gpg-preset-passphrase", "--preset", grip,
                    input=password + b"\n", check=True)
                del password
                count += 1
        print(f"Unlocked {count} GPG/SSH keys from KWallet.")
    finally:
        agent.close()


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, subprocess.CalledProcessError, StopIteration) as error:
        # Never include subprocess stdout, stderr, input, or secret data.
        raise SystemExit(f"GPG login unlock failed: {type(error).__name__}") from None
