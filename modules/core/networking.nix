{
  networking = {
    networkmanager.enable = true;
    modemmanager.enable = false;
    # WireGuard tunnel from the "synse-pc" NetworkManager profile.
    firewall.trustedInterfaces = [ "synse-pc" ];
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
