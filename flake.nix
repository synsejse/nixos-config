{
  description = "NixOS host configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    razerr-rs = {
      url = "github:synsejse/razerr-rs";
      flake = false;
    };
    linuxblaster-control = {
      # Keep the installed checkout's revision; upstream already has newer work.
      url = "github:synsejse/linuxblaster_control/765b5ec8ebf76d4250168af7225e6a1249e95191";
      flake = false;
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      lanzaboote,
      chaotic,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/nixos
          lanzaboote.nixosModules.lanzaboote
          chaotic.nixosModules.default
        ];
      };
    };
}
