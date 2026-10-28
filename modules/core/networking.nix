{
  networking = {
    networkmanager.enable = true;
    modemmanager.enable = false;
    firewall = {
      trustedInterfaces = [
        "synse-pc" # WireGuard NetworkManager profile.
        "saidler-vpn" # Interface configured in /etc/vpnc/saidler.conf.
      ];
      # Trust local devices without accepting arbitrary Internet sources.
      # These rules live in NixOS's managed chain and are removed on reload.
      extraCommands = ''
        iptables -w -A nixos-fw -i enp10s0 -s 192.168.0.0/24 -j nixos-fw-accept
        ip6tables -w -A nixos-fw -i enp10s0 -s fe80::/10 -j nixos-fw-accept
        ip6tables -w -A nixos-fw -i enp10s0 -s fc00::/7 -j nixos-fw-accept
      '';
    };
  };

  services = {
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
