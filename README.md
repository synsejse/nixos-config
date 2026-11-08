# Development VM

Branch `vm-work` adapts `synsejse/nixos-config` main for this QEMU VM.
Shared settings retain their upstream module paths, including polkit in
`modules/core/system.nix`. VM hardware lives in `hosts/nixos`.

Uses BIOS GRUB on /dev/sda, the VM root filesystem, Plasma, development tools,
T3 Code and Podman. Desktop hardware, gaming, VPN and Secure Boot modules are
not imported. Android tooling and Ghostty are removed.

The canonical checkout is `/etc/nixos`; `nh` uses this path.
Build with `nixos-rebuild build --flake /etc/nixos#nixos` and activate with
`sudo nixos-rebuild switch --flake /etc/nixos#nixos`.
