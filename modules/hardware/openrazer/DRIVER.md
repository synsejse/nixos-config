# DeathAdder V3 Pro receiver reliability

The transport patch targets OpenRazer 3.12.4. It applies after the existing
HyperPolling, power and DPI patches in `default.nix`.

## Hardware evidence

Captured on 2026-10-30 with a DeathAdder V3 Pro wireless receiver (`1532:00c3`),
on kernel `7.3.0-cachyos`. Both OpenRazer and razerr-rs services were stopped
during each raw HID capture. Only settings queries were sent; no settings were
changed. Services were restored after each capture.

The receiver sometimes returns the previous command's response, or a matching
header with partially updated payload/checksum bytes. This happens without
concurrent application or daemon requests. The evidence points to receiver or
firmware response handling, but does not establish its internal cause.

- Waiting 31, 60 or 100 ms between SET_REPORT and GET_REPORT did not eliminate
  invalid replies. Repeating GET_REPORT alone did not recover the observed
  mismatches.
- In a second capture, 59 of 144 queries had an invalid first reply (wrong
  command or checksum). All 59 recovered on the second complete query.
- Additional gaps of 20 or 60 ms between commands did not prevent the failures.
- The six tested queries were DPI, DPI stages, charging status, battery level,
  idle time and low-battery threshold. Threshold, idle and battery reads were
  valid throughout these isolated captures; the initial kernel logs showed
  stale DPI replies during normal operation.

These are finite observations, not a guarantee for every firmware or sleep state.

## Patch behavior

`openrazer-driver-transport.patch`:

1. Propagates SET_REPORT failures without issuing GET_REPORT. Preserves negative
   USB errors, rejects short/oversized reports and avoids exporting failed reads.
2. For the six tested queries on PID `00c3`, checks command identity, transaction
   ID, protocol and checksum. Resends a query after a stale/torn or busy response,
   at most three total attempts, with a 20–21 ms retry delay. The existing
   59.9–60 ms receiver wait remains unchanged. The device mutex covers the whole
   recovery sequence.
3. Does not replay setters or queries on other PIDs. USB transfer failures,
   explicit command timeouts and unsupported commands are returned immediately.
4. Makes idle-time and threshold handlers propagate errors and reject incomplete
   or unsuccessful responses instead of interpreting unrelated bytes as values.

CRC validation is scoped to the captured receiver/query combination. Other
devices may have different firmware behavior. Recovery has a bounded attempt
count; USB control transfers still use the kernel's normal transfer timeout.

## Verification

The regression harness compiles the actual patched C functions with fault
injection at the USB boundary. It uses AddressSanitizer and UndefinedBehaviorSanitizer;
it does not create a fake daemon or access hardware.

```sh
python3 tests/check-driver.py /path/to/patched/openrazer/source
nix build /etc/nixos#nixosConfigurations.nixos.config.hardware.openrazer.packages.kernel
```

Checks cover transfer failures, truncated/oversized replies, wrong commands,
invalid checksums, busy/unsupported/timeout responses, bounded recovery, write
non-repetition, other-device behavior and power-setting error propagation.

On the local system, the patched module passed 72 consecutive hardware reads
(12 cycles of the six queries), followed by 72 successful D-Bus reads with both
services running. Normal background polling also ran without recurring settings
read errors during the observation window. The module and full NixOS
configuration both built successfully. The full build requires `--impure` because
this machine's configuration includes razerr-rs from its absolute local source path.
The configuration was activated with `nixos-rebuild test` and then `switch`.
The loaded module and the module in the active/default system generation match;
both services are running and threshold readback is 5%.

## Polling write correction

A follow-up hardware capture confirmed that the second extended polling write
(`00:40`, mode `01`) returns timeout status `04` with transaction ID `ff`, and
success status `02` with `1f`. Both mode `00` and mode `01` acknowledged repeated
1000/8000 Hz changes with `1f`; hardware readback matched. The original 8000 Hz
setting was restored. The earlier local HyperPolling patch had placed `00c3`
in the generic dongle's `ff` second-write group.

`openrazer-driver-polling.patch`, applied after the transport patch:

- Uses `1f` for both writes on `00c3`, holding the device mutex across the pair.
- Validates each acknowledgement's status, transaction ID, echoed mode/rate,
  payload length and checksum. Neither write is automatically replayed.
- Returns errors from either command. A second-command failure can leave a
  partially applied setting; there is no speculative rollback or false success.
- Rejects malformed, overflowing and unadvertised rates before any USB transfer.
- Propagates failures from the generic polling setter too, while preserving
  other devices' existing transaction routing.
- Validates extended polling readback, rejects unknown rate codes, and adds
  `00:c0` to the receiver's bounded read-recovery queries. The captured firmware
  declares payload size **1**, despite placing the rate in **argument 1**; the
  complete 90-byte reply and checksum are checked before decoding that format.

`openrazer-daemon-polling.patch` updates the cached rate only after the sysfs
write and close have succeeded. This prevents failed writes from being reported
as the newly selected rate by the daemon's cached getter.

The C regression harness covers both command destinations, serialization,
first/second-command failures, bad acknowledgements, parser rejection, and the
polling reply's size quirk. Cache ordering can be checked against the built
Python file with:

```sh
python3 tests/check-polling-cache.py /path/to/openrazer_daemon/dbus_services/dbus_methods/mamba.py
```

The polling capture changes only the polling rate, restores its original value,
and restores both user services. Keep the receiver connected:

```sh
sudo python3 diagnostics/capture-polling-writes.py > polling-writes.jsonl
```

The polling fixes were activated with `test` followed by `switch`. The loaded
module matches the active/default system generation, and the running daemon
uses the cache-order fix. Live verification passed seven valid sysfs writes,
rejected six invalid inputs, and preserved DPI, stages, idle time and threshold.
Four further D-Bus 1000/8000 Hz round-trips matched both cached and hardware
readback; an unsupported D-Bus rate was rejected. The original 8000 Hz rate was
restored. No startup polling timeout, failed USB request or recurring settings
read error appeared in the post-installation verification logs.

When testing by unloading/reloading the module, retrigger the receiver's HID
`add` event and wait for udev before restarting OpenRazer. Rebinding alone
recreates the settings attributes as root-owned and does not rerun the normal
OpenRazer group-permission rule. Normal boot/hotplug runs this rule automatically.

The read-only diagnostic requires local sudo authentication for hidraw access:

```sh
sudo python3 diagnostics/capture-replies.py timing > timing.jsonl
sudo python3 diagnostics/capture-replies.py recovery > recovery.jsonl
```

It discovers the receiver's settings interface, pauses the two user services,
captures replies, and restores the services even on interruption. Keep the
receiver connected and move the mouse occasionally during capture.

## Related upstream reports

- [Invalid device readings, including DeathAdder V3 Pro](https://github.com/openrazer/openrazer/issues/2122)
- [DeathAdder receiver timing suggestion](https://github.com/openrazer/openrazer/issues/2547#issuecomment-3428944391)
- [Threshold read failures on Basilisk V3 Pro](https://github.com/openrazer/openrazer/issues/2910)

The local patch does not depend on the daemon cache/clamping approach proposed
in PR #2911, and does not alter razerr-rs warning handling.
