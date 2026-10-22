{ pkgs, ... }:

{
  users.users.synse.packages = with pkgs; [
    chatgpt-linux
    (discord.override {
      withOpenASAR = true;
      withVencord = true;
    })
    ghostty
    google-chrome
    jetbrains-toolbox
    mission-center
    qbittorrent
    zed-editor

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
