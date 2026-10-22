{ pkgs, ... }:

{
  users.users.root.shell = pkgs.fish;

  users.users.synse = {
    shell = pkgs.fish;
    isNormalUser = true;
    description = "synse";
    extraGroups = [ "wheel" ];
  };

  security.sudo.execWheelOnly = true;
}
