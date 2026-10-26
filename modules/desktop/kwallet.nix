{ pkgs, ... }:

# Use KWallet for applications that access the Secret Service API.
{
  services = {
    gnome.gnome-keyring.enable = false;
    dbus.packages = [
      (pkgs.writeTextDir "share/dbus-1/services/org.freedesktop.secrets.service" ''
        [D-BUS Service]
        Name=org.freedesktop.secrets
        Exec=${pkgs.kdePackages.kwallet}/bin/ksecretd
      '')
    ];
  };

  # Complete KWallet's PAM login with an explicit socket path.
  systemd.user.services.plasma-kwallet-pam = {
    overrideStrategy = "asDropin";
    wantedBy = [ "graphical-session.target" ];
    unitConfig.ConditionPathIsSocket = "%t/kwallet5.socket";
    environment.PAM_KWALLET5_LOGIN = "%t/kwallet5.socket";
  };
}
