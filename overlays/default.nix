# Local packages. Feature-specific overrides live with their modules.
{ inputs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      discord-context-translate = final.callPackage ../pkgs/discord-context-translate { };
      mocktail = final.callPackage ../pkgs/mocktail {
        mocktailSource = inputs.mocktail;
      };
      mocktail-vr = final.callPackage ../pkgs/mocktail-vr { };
      android-device-sdk = final.callPackage ../pkgs/android-device-sdk { };
      t3code = final.callPackage ../pkgs/t3code { };
      linuxblaster-control = final.callPackage "${inputs.linuxblaster-control}/nix/package.nix" { };
      razerr-rs = final.callPackage "${inputs.razerr-rs}/nix/package.nix" { };
    })
  ];
}
