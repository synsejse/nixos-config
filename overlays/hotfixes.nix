# Temporary nixpkgs fixes. Each one should stop applying on its own once
# upstream catches up; delete it when it does.
{ lib, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      # Temporary workaround for master's cloud-hypervisor 54.0 cargoHash.
      # Stops applying once nixpkgs changes the affected version or hash.
      cloud-hypervisor = prev.cloud-hypervisor.overrideAttrs (
        old:
        let
          cargoHash = "sha256-t4x5FaOuUUG98TqTjumdisizTDcdueOh4da2kj7wUDo=";
        in
        lib.optionalAttrs
          (old.version == "54.0" && old.cargoHash == "sha256-1xgpqoJeIXf7WqWYCHNPz5XzgbM8WtydGzT0q1qSYts=")
          {
            inherit cargoHash;
            cargoDeps = prev.rustPlatform.fetchCargoVendor {
              inherit (old) pname version src;
              hash = cargoHash;
            };
          }
      );
    })
  ];
}
