# Local packages. Feature-specific overrides live with their modules.
{ inputs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      android-device-sdk = final.callPackage ../pkgs/android-device-sdk.nix { };
      chatgpt-linux = final.callPackage ../pkgs/chatgpt-linux.nix { };
      t3code = final.callPackage ../pkgs/t3code.nix { };
      razerr-rs = final.callPackage ../pkgs/razerr-rs.nix {
        razerrSource = inputs.razerr-rs;
      };
    })
  ];
}
