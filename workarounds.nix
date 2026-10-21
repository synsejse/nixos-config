{ lib, pkgs, ... }:

{
  # COSMIC enables this globally; it overwrites audio threads' real-time priorities.
  services.system76-scheduler.enable = false;

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

      # FortiGate email MFA uses XAuth type 2 (OTP), absent from upstream vpnc.
      vpnc = prev.vpnc.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./vpnc-fortigate-otp.patch ];
      });

      # LiquidBounce's embedded Chromium browser (MCEF) needs these libraries.
      prismlauncher = prev.prismlauncher.override {
        additionalLibs = with final; [
          libxi
          libxkbcommon
          glib
          nspr
          nss
          dbus
          at-spi2-atk
          at-spi2-core
          cups
          libxcomposite
          libxdamage
          libxfixes
          libgbm
          expat
          libxcb
          cairo
          pango
        ];
      };

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

  # Let each desktop select its Qt integration; COSMIC defaults to global qt5ct.
  qt.platformTheme = null;

  # KVM compatibility settings for nested virtualisation and macOS guests.
  boot.extraModprobeConfig = ''
    options kvm_amd nested=1
    options kvm ignore_msrs=1 report_ignored_msrs=0
  '';

  # Grant tablet-device access and expose AMD CPU energy counters to monitors.
  services.udev.extraRules = ''
    KERNEL=="hidraw*", ATTRS{idVendor}=="056a", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0ac3", TAG+="uaccess"
    ACTION=="add|change", SUBSYSTEM=="powercap", KERNEL=="intel-rapl:*", TEST=="energy_uj", RUN+="${pkgs.coreutils}/bin/chmod a+r /sys%p/energy_uj"
  '';

  # osu! and other .NET AppImages need ICU inside the FHS environment.
  programs.appimage.package = pkgs.appimage-run.override {
    extraPkgs = pkgs: [ pkgs.icu ];
  };

  programs.steam.package = pkgs.steam.override {
    extraProfile = ''
      # Let every Steam VR game discover WiVRn's active OpenXR runtime.
      export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
      # Let Windows games such as VRChat detect the local time zone.
      unset TZ
    '';
  };
}
