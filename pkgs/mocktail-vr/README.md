# Mocktail VR

The source is pinned to the upstream `vr` branch revision
`c17db21e1d49fc6fc303088453a40de322ee4405` (checked 2026-11-16). `default.nix`
fetches its submodules at upstream's pinned revisions, enables VR, and packages all
runtime helpers. `readiness-canary.patch` preserves the local fix that runs payload
readiness checks without requiring a headset.

`launcher.sh` keeps the existing separate VR configuration/data directories and
selects the system WiVRn runtime. The package wraps its helpers with the required
graphics libraries and GLib TLS backend. No `nix develop` or home-directory build
tree is used at launch.

Connect the headset to WiVRn before launching. `mocktail-vr --help` works without a
headset; full VR gameplay requires a connected headset and a valid Roblox login.
