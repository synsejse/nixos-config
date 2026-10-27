{ pkgs, ... }:

{
  users.users.synse.packages = with pkgs; [
    jetbrains-toolbox
    zed-editor
  ];
}
