{ pkgs, ... }:

{
  boot.kernelModules = [ "kvm-amd" ];

  # KVM compatibility settings for nested virtualisation and macOS guests.
  boot.extraModprobeConfig = ''
    options kvm_amd nested=1
    options kvm ignore_msrs=1 report_ignored_msrs=0
  '';

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
    };
  };

  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  programs.virt-manager.enable = true;

  environment.systemPackages = [ pkgs.virt-viewer ];

  users.users.synse.extraGroups = [
    "kvm"
    "libvirtd"
  ];
}
