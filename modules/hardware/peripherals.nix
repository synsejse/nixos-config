{
  hardware = {
    bluetooth.enable = true;
    wooting.enable = true;
    opentabletdriver.enable = true;
  };

  # iOS device access.
  services.usbmuxd.enable = true;

  # Grant tablet-device access.
  services.udev.extraRules = ''
    KERNEL=="hidraw*", ATTRS{idVendor}=="056a", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0ac3", TAG+="uaccess"
  '';
}
