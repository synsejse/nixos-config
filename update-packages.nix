# Avoid nix-update's flake metadata paths, which may be lazy in Nix 2.35+.
{ }:
(builtins.getFlake (toString ./.)).packages.${builtins.currentSystem}
