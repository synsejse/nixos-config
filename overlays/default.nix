# Local packages. Feature-specific overrides live with their modules.
{ inputs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      chatgpt-linux = final.callPackage ../pkgs/chatgpt-linux.nix { };
      t3code = final.callPackage ../pkgs/t3code.nix { };
      chromaven = final.callPackage ../pkgs/chromaven.nix {
        chromavenSource = inputs.chromaven-src;
        ravenSource = inputs.raven-src;
      };
    })
  ];
}
