# Local packages

Each package has its own directory, with `default.nix` and any patches, launchers,
desktop entries, or bundled sources beside it. `../overlays/default.nix` exposes
the packages; `../modules/apps.nix` selects desktop applications for this host.

- `discord-vencord`: Discord with OpenASAR and Vencord. OpenASAR is patched for
  read-only Nix modules, and the video-decoding flag is part of the package.
- `mocktail`: upstream's package from the pinned release tag, wrapped so the
  runtime and its helpers find their graphics libraries and each other.
- `mocktail-vr`: pinned upstream VR source, pinned vendored dependencies, the
  headset-independent readiness patch, and the WiVRn launcher. User configuration,
  login data, and payloads remain in the existing XDG `mocktail-vr` directories.

These applications are retained by the NixOS system profile. They do not depend on
home-directory `result` links, saved development shells, or local build folders.
