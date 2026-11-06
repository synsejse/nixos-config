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
      chatgpt-linux = final.callPackage ../pkgs/chatgpt-linux { };
      t3code = final.callPackage ../pkgs/t3code { };
      linuxblaster-control = final.callPackage ../pkgs/linuxblaster-control {
        linuxblasterSource = inputs.linuxblaster-control;
      };
      razerr-rs = final.callPackage ../pkgs/razerr-rs {
        razerrSource = inputs.razerr-rs;
      };
    })
  ];
}
