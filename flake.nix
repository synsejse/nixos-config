{
  description = "NixOS host configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    razerr-rs = {
      url = "github:synsejse/razerr-rs/main";
      flake = false;
    };
    linuxblaster-control = {
      url = "github:synsejse/linuxblaster_control/main";
      flake = false;
    };
    mocktail = {
      url = "github:komaruworld/mocktail/1.0.5";
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
          inputs.spicetify-nix.nixosModules.default
        ];
      };
    };
}
