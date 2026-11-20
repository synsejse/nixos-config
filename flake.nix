{
  description = "Development VM, adapted from synsejse/nixos-config";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      updateSystem = pkgs.writeShellApplication {
        name = "update-system";
        runtimeInputs = [
          pkgs.git
          pkgs.nix
          pkgs.nix-update
          pkgs.python3
        ];
        text = ''
          exec python3 ${./scripts/update.py} "$@"
        '';
      };
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;

      packages.${system} = {
        inherit (self.nixosConfigurations.nixos.pkgs) t3code;
      };
      apps.${system} = {
        update = {
          type = "app";
          program = "${updateSystem}/bin/update-system";
          meta.description = "Update all inputs and custom packages, then build the system";
        };
      };

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./hosts/nixos ];
      };
    };
}
