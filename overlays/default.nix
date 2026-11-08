# Local packages. Feature-specific overrides live with their modules.
{ inputs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      kwi = final.callPackage ../pkgs/kwi { };
      discord-vencord = final.callPackage ../pkgs/discord-vencord { };
      mocktail = final.callPackage ../pkgs/mocktail {
        mocktailSource = inputs.mocktail;
      };
      mocktail-vr = final.callPackage ../pkgs/mocktail-vr { };
      android-device-sdk = final.callPackage ../pkgs/android-device-sdk { };
      t3code = final.callPackage ../pkgs/t3code { };
      saidler-vpn = final.callPackage ../pkgs/saidler-vpn { };
      linuxblaster-control = final.callPackage "${inputs.linuxblaster-control}/nix/package.nix" { };
      razerr-rs = (final.callPackage "${inputs.razerr-rs}/nix/package.nix" { }).overrideAttrs (old: {
        # The Rust setup hook now requires the system AWS-LC library.
        buildInputs = (old.buildInputs or [ ]) ++ [ final.aws-lc ];
      });
    })
  ];
}
