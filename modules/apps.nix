{ pkgs, ... }:
{
  users.users.synse.packages = with pkgs; [
    t3code unzip zip p7zip
  ];
}
