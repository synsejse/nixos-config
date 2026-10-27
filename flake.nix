{
  description = "NixOS host configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    # Refresh local app snapshots with: nix flake update chromaven-src raven-src
    chromaven-src = {
      url = "path:/home/synse/Documents/Coding/PersonalDev/Chromaven";
      flake = false;
    };
    raven-src = {
      url = "path:/home/synse/Documents/Coding/PersonalDev/Raven";
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
