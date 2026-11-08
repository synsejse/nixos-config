{
  networking.networkmanager.enable = true;
  users.users.synse.extraGroups = [ "networkmanager" ];
}
