# Local packages

Each package has its own directory, with `default.nix` and any patches, launchers,
desktop entries, or bundled sources beside it. `../overlays/default.nix` exposes
the packages; `../modules/apps.nix` selects desktop applications for this host.

- `mocktail`: upstream's package from the pinned release tag, wrapped so the
  runtime and its helpers find their graphics libraries and each other.
- `mocktail-vr`: pinned upstream VR source, pinned vendored dependencies, the
  headset-independent readiness patch, and the WiVRn launcher. User configuration,
  login data, and payloads remain in the existing XDG `mocktail-vr` directories.
- `saidler-vpn`: FortiGate-patched vpnc and a launcher that reads the email code
  over IMAP. Passwords and mail settings stay in `~/.config/saidler-vpn/`.
- `t3code`: T3 Code nightly, with the Wayland launcher and Android device tools.

These applications are retained by the NixOS system profile. They do not depend on
home-directory `result` links, saved development shells, or local build folders.

Discord uses Nixpkgs' Vencord and OpenASAR options in `../modules/apps.nix`,
without a local package, version pin, or video-decoding override.

## Updating everything

Run from any directory, without sudo:

```sh
nix run /etc/nixos#update
```

This updates all flake inputs, including Nixpkgs, Chaotic, Spicetify, razerr-rs,
and Linuxblaster Control. It checks the latest stable Mocktail and Lanzaboote
releases, updates the T3 Code nightly and Mocktail VR branch pins and hashes,
then builds the full NixOS system. Mocktail VR's submodules follow the selected
upstream revision automatically.

The command edits `flake.nix`, `flake.lock`, and the custom package definitions as
needed. It does not commit, push, or activate a system generation. No timer is
enabled; run it whenever you want to update.

After a successful build, activate through your usual NixOS rebuild:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

Restart updated applications after activation; reboot for kernel and desktop
updates. Commit the configuration changes when you want to keep or share the
update. With a config clone elsewhere, pass its path:

```sh
nix run /path/to/nixos-config#update -- /path/to/nixos-config
```

If an update or build fails, inspect `git diff` and
resolve the failure before rebuilding. Build failures leave the current system
generation running.
