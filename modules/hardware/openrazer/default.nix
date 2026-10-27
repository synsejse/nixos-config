{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Keep Polychromatic and its Python client on the same patched daemon.
  nixpkgs.overlays = [
    (final: prev: {
      # CachyOS's cached kernel uses the older module-certificate layout.
      # https://github.com/xddxdd/nix-cachyos-kernel/issues/111
      aggregateModules =
        modules:
        (prev.aggregateModules modules).overrideAttrs (
          old:
          let
            marker = "# Merge the single‐module certificates for external modules.";
            merge = "| xargs -d'\\n' cat >> modules.cer";
          in
          assert lib.hasInfix marker old.postBuild && lib.hasInfix merge old.postBuild;
          {
            postBuild =
              builtins.replaceStrings
                [ marker merge ]
                [
                  (marker + "\n        if test -e modules.cer; then")
                  ''
                    | while IFS= read -r certificate; do
                        if test -f "$certificate"; then
                          cat "$certificate" >> modules.cer
                        fi
                      done
                      fi
                  ''
                ]
                old.postBuild;
          }
        );

      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pythonFinal: pythonPrev: {
          openrazer-daemon = pythonPrev.openrazer-daemon.overridePythonAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              ./deathadder-v3-pro-daemon.patch
              ./transport-handoff.patch
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
          patches = (old.patches or [ ]) ++ [ ./deathadder-v3-pro-driver.patch ];
        });
  };

  environment.systemPackages = [ pkgs.polychromatic ];
}
