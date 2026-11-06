{ config, pkgs, ... }:

{
  # Keep polling support and daemon fixes in the Python package set.
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pythonFinal: pythonPrev: {
          openrazer-daemon = pythonPrev.openrazer-daemon.overridePythonAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              ./deathadder-v3-pro-daemon.patch
              ./transport-handoff.patch
              ./openrazer-daemon-power.patch
              ./openrazer-daemon-polling.patch
            ];
          });
        })
      ];
    })
  ];

  hardware.openrazer = {
    enable = true;
    users = [ "synse" ];
    # The CachyOS kernel uses a cross package set; these runtime shell tools
    # run on this host and can use the existing native packages.
    packages.kernel =
      (config.boot.kernelPackages.openrazer.override {
        inherit (pkgs) coreutils util-linux;
      }).overrideAttrs
        (old: {
          patches = (old.patches or [ ]) ++ [
            ./deathadder-v3-pro-driver.patch
            ./openrazer-driver-power.patch
            ./openrazer-driver-dpi.patch
            ./openrazer-driver-transport.patch
            ./openrazer-driver-polling.patch
          ];
        });
  };
}
