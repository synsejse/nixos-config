{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./saidler-vpn.nix
    ./workarounds.nix
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Avoid concurrent memory-heavy package builds; keep all CPU threads per build.
      max-jobs = 1;
      cores = 12;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };
  nixpkgs.config.allowUnfree = true;

  chaotic.mesa-git = {
    enable = true;
    fallbackSpecialisation = false;
  };

  boot = {
    kernelModules = [ "kvm-amd" ];
    kernelPackages = pkgs.linuxPackages_cachyos;

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      configurationLimit = 5;
    };
    loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    modemmanager.enable = false;
    firewall.trustedInterfaces = [ "synse-pc" ];
    firewall.allowedTCPPorts = [ 5173 ];
  };

  time.timeZone = "Europe/Bratislava";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "sk_SK.UTF-8";
      LC_IDENTIFICATION = "sk_SK.UTF-8";
      LC_MEASUREMENT = "sk_SK.UTF-8";
      LC_MONETARY = "sk_SK.UTF-8";
      LC_NAME = "sk_SK.UTF-8";
      LC_NUMERIC = "sk_SK.UTF-8";
      LC_PAPER = "sk_SK.UTF-8";
      LC_TELEPHONE = "sk_SK.UTF-8";
      LC_TIME = "sk_SK.UTF-8";
    };
  };

  hardware = {
    wooting.enable = true;
    amdgpu.overdrive.enable = true;
    opentabletdriver.enable = true;
  };

  security.rtkit.enable = true;

  # Complete KWallet's PAM login in COSMIC as well as Plasma. COSMIC does not
  # import PAM_KWALLET5_LOGIN into the systemd user manager itself.
  systemd.user.services.plasma-kwallet-pam = {
    overrideStrategy = "asDropin";
    wantedBy = [ "graphical-session.target" ];
    unitConfig.ConditionPathIsSocket = "%t/kwallet5.socket";
    environment.PAM_KWALLET5_LOGIN = "%t/kwallet5.socket";
  };
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
    };
  };
  security.sudo.execWheelOnly = true;

  services = {
    # Share the existing KDE wallet between Plasma and COSMIC.
    gnome.gnome-keyring.enable = false;
    dbus.packages = [
      (pkgs.writeTextDir "share/dbus-1/services/org.freedesktop.secrets.service" ''
        [D-BUS Service]
        Name=org.freedesktop.secrets
        Exec=${pkgs.kdePackages.kwallet}/bin/ksecretd
      '')
    ];
    cloudflare-warp.enable = true;
    wivrn = {
      enable = true;
      openFirewall = true;
      autoStart = false;
      highPriority = true;
      steam.package = config.programs.steam.package;
      config = {
        enable = true;
        json.application = [ pkgs.wayvr "--openxr" ];
      };
    };
    xserver.videoDrivers = [ "amdgpu" ];
    desktopManager.plasma6.enable = true;
    desktopManager.cosmic.enable = true;
    displayManager.sddm.enable = true;
    flatpak.enable = true;
    lact.enable = true;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
    kmscon.enable = true;
    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };

  programs = {
    fish.enable = true;
    starship.enable = true;
    virt-manager.enable = true;
    kdeconnect.enable = true;
    appimage = {
      enable = true;
      binfmt = true;
    };
    gamemode.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-qt;
    };
    nh = {
      enable = true;
      flake = "/etc/nixos";
    };
    nix-ld.enable = true;
    steam.enable = true;
  };

  users.users.root.shell = pkgs.fish;

  users.users.synse = {
    shell = pkgs.fish;
    isNormalUser = true;
    description = "synse";
    extraGroups = [
      "networkmanager"
      "wheel"
      "kvm"
      "libvirtd"
    ];
    packages = with pkgs; [
      (callPackage ./chatgpt-linux.nix { })
      (discord.override {
        withOpenASAR = true;
        withVencord = true;
      })
      easyeffects
      ghostty
      google-chrome
      heroic
      jetbrains-toolbox
      kdePackages.ksshaskpass
      mission-center
      prismlauncher
      qbittorrent
      zed-editor
      arj
      kdePackages.ark
      kdePackages.plasma-vault
      kdePackages.filelight
      lrzip
      p7zip
      rar
      unar
      unrar
      unzip
      zip
    ];
  };

  # Keep COSMIC's existing portals, with KWallet handling sandboxed app secrets.
  xdg.portal.config.cosmic = {
    default = [ "cosmic" "gtk" ];
    "org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
  };

  environment.systemPackages = with pkgs; [
    virt-viewer
    dmg2img
    python3
    swtpm
    android-tools
    scrcpy
    btop
    sbctl
    rocmPackages.rocminfo
    rocm-smi
    fastfetch
    git
    nixd
    nil
    mpv
    mangohud
    gh
    icu
  ];

  # Bound temporary crash-dump processing as well as retained dump files.
  systemd.coredump.settings.Coredump = {
    Storage = "external";
    Compress = true;
    ProcessSizeMax = "256M";
    ExternalSizeMax = "256M";
    MaxUse = "1G";
    KeepFree = "4G";
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
    algorithm = "zstd";
    priority = 100;
  };

  # Keep this at the release used for the initial NixOS installation.
  system.stateVersion = "26.05";
}
