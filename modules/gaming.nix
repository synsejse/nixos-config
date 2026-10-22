{ config, pkgs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
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
    })
  ];

  programs = {
    steam = {
      enable = true;
      package = pkgs.steam.override {
        extraProfile = ''
          # Let every Steam VR game discover WiVRn's active OpenXR runtime.
          export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
          # Let Windows games such as VRChat detect the local time zone.
          unset TZ
        '';
      };
    };
    gamemode.enable = true;
    appimage = {
      enable = true;
      binfmt = true;
      # osu! and other .NET AppImages need ICU inside the FHS environment.
      package = pkgs.appimage-run.override {
        extraPkgs = pkgs: [ pkgs.icu ];
      };
    };
  };

  services.wivrn = {
    enable = true;
    openFirewall = true;
    autoStart = false;
    highPriority = true;
    steam.package = config.programs.steam.package;
    config = {
      enable = true;
      json.application = [
        pkgs.wayvr
        "--openxr"
      ];
    };
  };

  environment.systemPackages = [ pkgs.mangohud ];

  users.users.synse.packages = with pkgs; [
    heroic
    prismlauncher
  ];
}
