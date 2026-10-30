#!/usr/bin/env python3
"""Read-only DeathAdder 00c3 response timing capture; no settings writes.

Run as root to access hidraw. Stops the two user services during capture and
restores their previous running state, including on Ctrl-C. Emits JSON lines.
"""
import argparse
import fcntl
import functools
import json
import os
from pathlib import Path
import pwd
import signal
import subprocess
import time

emit = functools.partial(print, flush=True)


def main(mode):
    if os.geteuid() != 0 or not os.environ.get("SUDO_USER"):
        raise SystemExit("Run with sudo from your normal user session.")
    user = pwd.getpwnam(os.environ["SUDO_USER"])
    systemctl = [
        "runuser", "-u", user.pw_name, "--", "env",
        f"XDG_RUNTIME_DIR=/run/user/{user.pw_uid}",
        f"DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/{user.pw_uid}/bus",
        "systemctl", "--user",
    ]
    devices = [p for p in Path('/sys/bus/hid/drivers/razermouse').glob('0003:1532:00C3.*')
               if (p / 'dpi').exists()]
    if len(devices) != 1:
        raise SystemExit("Expected exactly one DeathAdder V3 Pro 00c3 settings interface.")
    nodes = list((devices[0] / 'hidraw').glob('hidraw*'))
    if len(nodes) != 1:
        raise SystemExit("Expected one hidraw node on the settings interface.")
    units = ['razerr-rs.service', 'openrazer-daemon.service']
    active = [u for u in units if subprocess.run(systemctl + ['is-active', '--quiet', u]).returncode == 0]
    fd = None
    # Only documented GET commands. SET_REPORT selects a query; no setting setter.
    queries = [('dpi', 4, 0x85, 7, 0), ('threshold', 7, 0x81, 1, 0),
               ('stages', 4, 0x86, 38, 1), ('charging', 7, 0x84, 2, 0),
               ('idle', 7, 0x83, 2, 0), ('battery', 7, 0x80, 2, 0)]
    try:
        subprocess.run(systemctl + ['stop', *active], check=True) if active else None
        fd = os.open('/dev/' + nodes[0].name, os.O_RDWR | os.O_CLOEXEC)
        emit(json.dumps({'event': 'start', 'device': devices[0].name, 'active': active}))
        if mode == 'timing':
            for delay_ms in [60, 100, 31, 60]:
                for cycle in range(8):
                    for name, cls, cmd, size, storage in queries:
                        report = bytearray(90)
                        report[1], report[5], report[6], report[7], report[8] = 0x1f, size, cls, cmd, storage
                        report[88] = functools.reduce(int.__xor__, report[2:88], 0)
                        start = time.monotonic()
                        written = fcntl.ioctl(fd, 0xC05B4806, bytearray(b'\0' + report), True)
                        time.sleep(delay_ms / 1000)
                        for attempt in range(4):
                            buffer = bytearray(91)
                            length = fcntl.ioctl(fd, 0xC05B4807, buffer, True)
                            # HIDIOCGFEATURE preserves the leading zero report ID.
                            reply = buffer[1:91] if length == 91 else buffer[:90]
                            matches = length in (90, 91) and reply[2:5] == report[2:5] and reply[6:8] == report[6:8]
                            crc_ok = reply[88] == functools.reduce(int.__xor__, reply[2:88], 0)
                            emit(json.dumps({'query': name, 'delay_ms': delay_ms, 'cycle': cycle,
                                             'attempt': attempt, 'elapsed_ms': round((time.monotonic()-start)*1000, 2),
                                             'set_result': written, 'length': length,
                                             'matches': matches, 'crc_ok': crc_ok, 'reply': reply.hex()}))
                            if matches and reply[0] == 2:
                                break
                            time.sleep(0.02)
        else:
            for gap_ms in [0, 20, 60]:
                for cycle in range(8):
                    for name, cls, cmd, size, storage in queries:
                        report = bytearray(90)
                        report[1], report[5], report[6], report[7], report[8] = 0x1f, size, cls, cmd, storage
                        report[88] = functools.reduce(int.__xor__, report[2:88], 0)
                        for attempt in range(3):
                            time.sleep(gap_ms / 1000)
                            start = time.monotonic()
                            written = fcntl.ioctl(fd, 0xC05B4806, bytearray(b'\0' + report), True)
                            time.sleep(0.060)
                            buffer = bytearray(91)
                            length = fcntl.ioctl(fd, 0xC05B4807, buffer, True)
                            reply = buffer[1:91] if length == 91 else buffer[:90]
                            matches = length in (90, 91) and reply[2:5] == report[2:5] and reply[6:8] == report[6:8]
                            crc_ok = reply[88] == functools.reduce(int.__xor__, reply[2:88], 0)
                            emit(json.dumps({'query': name, 'gap_ms': gap_ms, 'cycle': cycle,
                                             'attempt': attempt, 'elapsed_ms': round((time.monotonic()-start)*1000, 2),
                                             'set_result': written, 'length': length,
                                             'matches': matches, 'crc_ok': crc_ok, 'reply': reply.hex()}))
                            if matches and crc_ok and reply[0] == 2:
                                break
                            time.sleep(0.020)
    finally:
        if fd is not None:
            os.close(fd)
        # Restore daemon before its client, even when capture fails.
        for unit in reversed(active):
            subprocess.run(systemctl + ['start', unit], check=True)
        emit(json.dumps({'event': 'restored', 'units': active}))


if __name__ == '__main__':
    def interrupted(signum, frame):
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM, interrupted)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["timing", "recovery"])
    main(parser.parse_args().mode)
