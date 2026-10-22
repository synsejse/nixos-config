{ pkgs, ... }:

{
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm.enable = true;
    gvfs.enable = true;
    switcherooControl.enable = true;
    flatpak.enable = true;
  };

  programs.kdeconnect.enable = true;

  users.users.synse.packages = with pkgs.kdePackages; [
    ark
    plasma-vault
    filelight
  ];
}
