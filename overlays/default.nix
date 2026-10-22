# Local packages. Feature-specific overrides live with their modules.
{
  nixpkgs.overlays = [
    (final: prev: {
      chatgpt-linux = final.callPackage ../pkgs/chatgpt-linux.nix { };
    })
  ];
}
