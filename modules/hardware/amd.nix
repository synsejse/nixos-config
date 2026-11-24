{ lib, pkgs, ... }:

{
  chaotic.mesa-git = {
    enable = true;
    fallbackSpecialisation = false;
  };

  hardware.amdgpu.overdrive.enable = true;
  boot.kernelParams = [
    # Disable DCN SubVP / FAMS2 (DC_DISABLE_SUBVP_FAMS) to prevent 18-28 ms
    # dcn401_dmub_hw_control_lock / inbox0 ACK stalls during low-load MCLK switches.
    "amdgpu.dcdebugmask=0x20000"
  ];
  services.xserver.videoDrivers = [ "amdgpu" ];
  services.lact.enable = true;

  nixpkgs.overlays = [
    (final: prev: {
      # btop only finds librocm_smi64 (AMD GPU stats) when built with ROCm support.
      btop = prev.btop.override { rocmSupport = true; };

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
