{ pkgs, ... }:

{
  users.users.synse.packages = with pkgs; [
    chatgpt-linux
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
}
