{ pkgs, ... }:

{
  networking = {
    networkmanager.enable = true;
    modemmanager.enable = false;
    nftables.enable = true;
    firewall = {
      trustedInterfaces = [
        "synse-pc" # WireGuard NetworkManager profile.
        "saidler-vpn" # Interface configured in /etc/vpnc/saidler.conf.
      ];
      # Trust local devices without accepting arbitrary Internet sources.
      extraInputRules = ''
        iifname "enp10s0" ip saddr 192.168.0.0/24 accept
        iifname "enp10s0" ip6 saddr { fe80::/10, fc00::/7 } accept
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    pangolin-client
    pangolin-cli
  ];

  systemd.services.pangolin-client = {
    description = "Pangolin client background service";
    documentation = [ "https://docs.pangolin.net" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [
      coreutils
      iproute2
      openresolv
      pangolin-cli
      polkit
      systemd
    ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.pangolin-client}/bin/pangolin-client --daemon";
      Restart = "on-failure";
      RestartSec = 2;
      KillMode = "mixed";
      TimeoutStopSec = 45;
      RuntimeDirectory = "pangolin-client";
      RuntimeDirectoryMode = "0755";
      StateDirectory = "pangolin-client";
      StateDirectoryMode = "0700";
      LogsDirectory = "pangolin-client";
      LogsDirectoryMode = "0755";
    };
  };

  services = {
    resolved.enable = true;
    cloudflare-warp.enable = true;
    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };

  users.users.synse.extraGroups = [ "networkmanager" ];
}
