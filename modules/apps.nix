{ pkgs, ... }:

{
  users.users.synse.packages = with pkgs; [
    chatgpt-linux
    chromaven
    (discord.override {
      withOpenASAR = true;
      withVencord = true;
      # Chromium's VA-API AV1 decode crashes the GPU process on mesa-git.
      commandLineArgs = "--disable-accelerated-video-decode";
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

  # Make the optional tray unit available without enabling login startup.
  systemd.packages = [ pkgs.chromaven ];

  # Ghostty 1.3.1 installs SIGUSR2 too late for systemd 262's startup check.
  # https://github.com/ghostty-org/ghostty/discussions/14394
  systemd.user.services."app-com.mitchellh.ghostty" = {
    overrideStrategy = "asDropin";
    # Inherit the desktop PATH instead of NixOS's minimal service PATH.
    enableDefaultPath = false;
    serviceConfig.Type = "notify";
  };
}
