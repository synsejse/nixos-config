{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
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

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    modemmanager.enable = false;
    firewall.trustedInterfaces = [ "synse-pc" ];
  };

  time.timeZone = "Europe/Bratislava";

#  fileSystems."/mnt/data" = {
#    device = "/dev/disk/by-uuid/cdced3ab-fa71-4ea8-b867-f7bda8a78bf5";
#    fsType = "ext4";
#  };

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
    amdgpu.overdrive.enable = true;
    nvidia = {
      open = true;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    opentabletdriver.enable = true;
  };

  security.rtkit.enable = true;
  security.sudo.execWheelOnly = true;

  services = {
    xserver.videoDrivers = [
      "nvidia"
      "amdgpu"
    ];
    desktopManager.plasma6.enable = true;
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

  users.users.synse = {
    isNormalUser = true;
    description = "synse";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      (discord.override {
        withOpenASAR = true;
        withVencord = true;
      })
      easyeffects
      inkscape
      google-chrome
      heroic
      kdePackages.ksshaskpass
      mission-center
      osu-lazer-bin
      prismlauncher
      protonup-qt
      qbittorrent
      zed-editor
      # archives
      arj
      kdePackages.ark
      kdePackages.plasma-vault
      lrzip
      p7zip
      rar
      unar
      unrar
      unzip
      zip
    ];
  };

  environment.systemPackages = with pkgs; [
    btop
    fastfetch
    git
    nixd
    nil
    mpv
    mangohud
    gh
  ];

  zramSwap = {
    enable = true;
    memoryPercent = 25;
    algorithm = "zstd";
    priority = 100;
  };

  # Keep this at the release used for the initial NixOS installation.
  system.stateVersion = "26.05";
}
