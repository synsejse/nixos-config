{ lib, pkgs, ... }:

{
  chaotic.mesa-git = {
    enable = true;
    fallbackSpecialisation = false;
  };

  hardware.amdgpu.overdrive.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  services.lact.enable = true;

  nixpkgs.overlays = [
    (final: prev: {
      # rocm-smi loads libdrm dynamically to resolve GPU names.
      rocm-smi = final.symlinkJoin {
        name = "rocm-smi";
        paths = [ final.rocmPackages.rocm-smi ];
        nativeBuildInputs = [ final.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/rocm-smi \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ final.libdrm ]}
        '';
      };
    })
  ];

  environment.systemPackages = with pkgs; [
    rocmPackages.rocminfo
    rocm-smi
  ];

  # Expose AMD CPU energy counters to monitors.
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="powercap", KERNEL=="intel-rapl:*", TEST=="energy_uj", RUN+="${pkgs.coreutils}/bin/chmod a+r /sys%p/energy_uj"
  '';
}
