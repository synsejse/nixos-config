# Local packages

This VM packages `t3code` through `overlays/default.nix` and selects it in
`modules/apps.nix`. T3 Code is packaged without Android SDK dependencies or
environment variables. Unused upstream package definitions are removed.
