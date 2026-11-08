# Local packages

Package sources retain their upstream paths. This VM exposes only `t3code`
through `overlays/default.nix` and selects it in `modules/apps.nix`.
T3 Code is packaged without Android SDK dependencies or environment variables.
The remaining upstream package definitions are inactive on this branch.
