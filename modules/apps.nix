{ pkgs, inputs, ... }:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  users.users.synse.packages = with pkgs; [
    linuxblaster-control
    razerr-rs
    discord-vencord
    mocktail
    mocktail-vr
    saidler-vpn
    ghostty
    spicetify-cli
    google-chrome
    mission-center
    qbittorrent
    t3code

    # Archive tools
    arj
    lrzip
    p7zip
    rar
    unar
    unrar
    unzip
    zip
  ];

  environment.systemPackages = [ pkgs.mpv ];

  programs.spicetify = {
    enable = true;
    experimentalFeatures = true;
    theme = spicePkgs.themes.default // {
      injectCss = true;
      replaceColors = true;
      injectThemeJs = true;
    };
    enabledExtensions = with spicePkgs.extensions; [
      fullAppDisplay
      keyboardShortcut
    ];
    enabledCustomApps = [
      spicePkgs.apps.marketplace
    ];
  };

  # Make the monitor available for D-Bus activation without enabling login startup.
  systemd.packages = [ pkgs.razerr-rs ];
  services.dbus.packages = [ pkgs.razerr-rs ];

  # Sound Blaster X4 control port for the desktop session; ModemManager ignores it.
  services.udev.packages = [ pkgs.linuxblaster-control ];

  systemd.user.services."app-com.mitchellh.ghostty" = {
    overrideStrategy = "asDropin";
    # Inherit the desktop PATH instead of NixOS's minimal service PATH.
    enableDefaultPath = false;
  };
}
