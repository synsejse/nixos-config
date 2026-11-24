{ pkgs, ... }:

{
  users.users.synse = {
    shell = pkgs.fish;
    isNormalUser = true;
    autoSubUidGidRange = true;
    description = "synse";
    extraGroups = [ "wheel" ];
  };

  security.sudo.execWheelOnly = true;
}
