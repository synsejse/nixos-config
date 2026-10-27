{
  imports = [
    ./core/nix.nix
    ./core/boot.nix
    ./core/locale.nix
    ./core/networking.nix
    ./core/users.nix
    ./core/shell.nix
    ./core/system.nix

    ./hardware/amd.nix
    ./hardware/peripherals.nix
    ./hardware/openrazer

    ./desktop/plasma.nix
    ./desktop/kwallet.nix
    ./desktop/audio.nix

    ./virtualisation.nix
    ./gaming.nix
    ./apps.nix
    ./coding
    ./saidler-vpn
  ];
}
