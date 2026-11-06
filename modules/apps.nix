{ pkgs, ... }:

{
  users.users.synse.packages = with pkgs; [
    chatgpt-linux
    linuxblaster-control
    razerr-rs
    discord-context-translate
    mocktail
    mocktail-vr
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

  # ContextTranslate uses its hosted backend; no local model server is needed.
  services.ollama.enable = false;

  # Make the monitor available for D-Bus activation without enabling login startup.
  systemd.packages = [ pkgs.razerr-rs ];
  services.dbus.packages = [ pkgs.razerr-rs ];

  # Sound Blaster X4 control port for the desktop session; ModemManager ignores it.
  services.udev.packages = [ pkgs.linuxblaster-control ];

  # Ghostty 1.3.1 installs SIGUSR2 too late for systemd 262's startup check.
  # https://github.com/ghostty-org/ghostty/discussions/14394
  systemd.user.services."app-com.mitchellh.ghostty" = {
    overrideStrategy = "asDropin";
    # Inherit the desktop PATH instead of NixOS's minimal service PATH.
    enableDefaultPath = false;
    serviceConfig.Type = "notify";
  };
}
