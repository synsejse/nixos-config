# Local packages

This VM packages `t3code` through `overlays/default.nix` and selects it in
`modules/apps.nix`. T3 Code is packaged without Android SDK dependencies or
environment variables. Unused upstream package definitions are removed.

## Updating everything

Run from any directory, without sudo:

```sh
nix run /etc/nixos#update
```

This updates the `nixpkgs` flake input, updates the T3 Code nightly pin and
hash, then builds the full NixOS system.

The command edits `flake.lock` and `pkgs/t3code/default.nix` as needed. It does
not commit, push, or activate a system generation. No timer is enabled; run it
whenever you want to update.

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

If an update or build fails, inspect `git diff` and resolve the failure before
rebuilding. Build failures leave the current system generation running.
