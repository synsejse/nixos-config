{ pkgs, ... }:

{
  users.users.synse.packages = with pkgs; [
    chatgpt-linux
    razerr-rs
    (discord.override {
      withOpenASAR = true;
      withVencord = true;
    })
    ghostty
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

  # Make the monitor available for D-Bus activation without enabling login startup.
  systemd.packages = [ pkgs.razerr-rs ];
  services.dbus.packages = [ pkgs.razerr-rs ];

  # Ghostty 1.3.1 installs SIGUSR2 too late for systemd 262's startup check.
  # https://github.com/ghostty-org/ghostty/discussions/14394
  systemd.user.services."app-com.mitchellh.ghostty" = {
    overrideStrategy = "asDropin";
    # Inherit the desktop PATH instead of NixOS's minimal service PATH.
    enableDefaultPath = false;
    serviceConfig.Type = "notify";
  };
}
