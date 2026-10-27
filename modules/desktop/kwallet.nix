{ pkgs, ... }:

let
  gpgLoginUnlock = pkgs.writeShellApplication {
    name = "gpg-login-unlock";
    runtimeInputs = [
      pkgs.python3
      pkgs.gnupg
      pkgs.libsecret
    ];
    text = ''
      exec python3 ${./gpg-login-unlock.py} "$@"
    '';
  };
in

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

  # Allow pinentry-qt to use KWallet's Secret Service on KDE as well.
  systemd.user.services.gpg-agent.environment.PINENTRY_KDE_USE_WALLET = "1";

  users.users.synse.packages = [ gpgLoginUnlock ];

  # Enrol passphrases once with `gpg-login-unlock --setup`.
  # Only encrypted KWallet storage holds them; Nix contains no passphrases.
  systemd.user.services.gpg-login-unlock = {
    description = "Unlock GPG and SSH keys from KWallet";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wants = [ "plasma-kwallet-pam.service" ];
    requires = [ "gpg-agent.service" ];
    after = [
      "plasma-kwallet-pam.service"
      "gpg-agent.service"
    ];
    unitConfig.ConditionUser = "synse";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${gpgLoginUnlock}/bin/gpg-login-unlock";
      RemainAfterExit = true;
    };
  };
}
