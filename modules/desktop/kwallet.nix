{ pkgs, ... }:

# Share the existing KDE wallet between Plasma and labwc.
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

  # Complete KWallet's PAM login for labwc as well as Plasma, with an explicit
  # socket path for sessions that do not import PAM_KWALLET5_LOGIN themselves.
  systemd.user.services.plasma-kwallet-pam = {
    overrideStrategy = "asDropin";
    wantedBy = [ "graphical-session.target" ];
    unitConfig.ConditionPathIsSocket = "%t/kwallet5.socket";
    environment.PAM_KWALLET5_LOGIN = "%t/kwallet5.socket";
  };

  xdg.portal.config.labwc."org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
}
