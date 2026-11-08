{
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  services.gvfs.enable = true;
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  programs.firefox.enable = true;
}
