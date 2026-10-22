{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../../overlays
  ];

  networking.hostName = "nixos";

  # Keep this at the release used for the initial NixOS installation.
  system.stateVersion = "26.05";
}
