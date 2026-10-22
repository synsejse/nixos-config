{ pkgs, ... }:

{
  programs = {
    fish.enable = true;
    starship.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-qt;
    };
  };

  environment.systemPackages = with pkgs; [
    python3
    btop
    fastfetch
    git
    gh
    nixd
    android-tools
    scrcpy
    dmg2img
  ];
}
