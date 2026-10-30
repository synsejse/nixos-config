#!/usr/bin/env python3
"""Probe 00c3 polling writes, restore the original rate and user services.

Only polling rate is written. No write is automatically retried. Requires sudo
for hidraw; leave the receiver connected throughout the brief test.
"""
import fcntl
import functools
import json
import os
from pathlib import Path
import pwd
import signal
import subprocess
import time

RATES = {125: 64, 250: 32, 500: 16, 1000: 8, 2000: 4, 4000: 2, 8000: 1}


def emit(value):
    print(json.dumps(value), flush=True)


def main():
    if os.geteuid() != 0 or not os.environ.get('SUDO_USER'):
        raise SystemExit('Run with sudo from the normal user session.')
    devices = [p for p in Path('/sys/bus/hid/drivers/razermouse').glob('0003:1532:00C3.*')
               if (p / 'poll_rate').exists()]
    assert len(devices) == 1, 'Expected exactly one 00c3 receiver.'
    device = devices[0]
    nodes = list((device / 'hidraw').glob('hidraw*'))
    assert len(nodes) == 1
    user = pwd.getpwnam(os.environ['SUDO_USER'])
    ctl = ['runuser', '-u', user.pw_name, '--', 'env',
           f'XDG_RUNTIME_DIR=/run/user/{user.pw_uid}',
           f'DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/{user.pw_uid}/bus',
           'systemctl', '--user']
    active = [u for u in ['razerr-rs.service', 'openrazer-daemon.service']
              if subprocess.run(ctl + ['is-active', '--quiet', u]).returncode == 0]
    fd = None
    original = None
    second_supported = False

    def exchange(tid, command, args, label):
        assert command in (0x40, 0xc0) and tid in (0x1f, 0xff)
        report = bytearray(90)
        report[1], report[5], report[7] = tid, len(args), command
        report[8:8+len(args)] = bytes(args)
        report[88] = functools.reduce(int.__xor__, report[2:88], 0)
        sent = fcntl.ioctl(fd, 0xC05B4806, bytearray(b'\0' + report), True)
        assert sent == 91, sent
        time.sleep(.060)
        buffer = bytearray(91)
        length = fcntl.ioctl(fd, 0xC05B4807, buffer, True)
        reply = buffer[1:91] if length == 91 else buffer[:90]
        matches = length in (90, 91) and reply[1:5] == report[1:5] and reply[6:8] == report[6:8]
        crc_ok = reply[88] == functools.reduce(int.__xor__, reply[2:88], 0)
        emit({'label':label, 'request':report.hex(), 'reply':reply.hex(),
              'length':length, 'matches':matches, 'crc_ok':crc_ok})
        return reply, matches and crc_ok and reply[0] == 2

    def read_rate(label):
        for attempt in range(3):
            reply, good = exchange(0x1f, 0xc0, [0], label)
            if good and reply[5] >= 1 and reply[9] in RATES.values():
                return next(rate for rate, value in RATES.items() if value == reply[9])
            time.sleep(.020)
        raise RuntimeError('Could not read a validated polling rate.')

    def write_rate(tid, bank, rate, label):
        assert bank in (0,1) and rate in RATES
        reply, good = exchange(tid, 0x40, [bank, RATES[rate]], label)
        emit({'label':label + '-readback', 'rate':read_rate(label + '-query'),
              'acknowledged':good, 'status':reply[0]})
        return good

    try:
        if active:
            subprocess.run(ctl + ['stop', *active], check=True)
        fd = os.open('/dev/' + nodes[0].name, os.O_RDWR | os.O_CLOEXEC)
        original = read_rate('original')
        emit({'event':'start', 'original_rate':original, 'device':device.name})
        write_rate(0xff, 1, original, 'existing-second-write-ff')
        second_supported = write_rate(0x1f, 1, original, 'candidate-second-write-1f')
        for rate in [1000, 8000, 1000, 8000]:
            write_rate(0x1f, 0, rate, f'first-write-{rate}')
            if second_supported:
                write_rate(0x1f, 1, rate, f'second-write-{rate}')
    finally:
        try:
            if fd is not None and original is not None:
                write_rate(0x1f, 0, original, 'restore-first')
                if second_supported:
                    write_rate(0x1f, 1, original, 'restore-second')
                assert read_rate('restore-verify') == original
                emit({'event':'rate_restored', 'rate':original})
        finally:
            if fd is not None:
                os.close(fd)
            for unit in reversed(active):
                subprocess.run(ctl + ['start', unit], check=True)
            emit({'event':'services_restored', 'units':active})


if __name__ == '__main__':
    def interrupted(signum, frame):
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM, interrupted)
    main()
