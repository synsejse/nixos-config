# Saidler IPsec IKEv1 VPN: PSK + XAuth password + email OTP.
# /etc/vpnc/saidler.conf holds the gateway, username, PSK, and DH14 settings.
# The launching user's ~/.config/saidler-vpn/ holds `password`, `mail-password`,
# and `mail.ini` (IMAP host, user, and code sender); none is stored in Nix.
{
  lib,
  coreutils,
  iproute2,
  kdePackages,
  kmod,
  makeDesktopItem,
  python3,
  symlinkJoin,
  vpnc,
  writeScript,
  writeShellScriptBin,
}:

let
  # FortiGate email MFA uses XAuth type 2 (OTP), absent from upstream vpnc.
  vpncOtp = vpnc.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./vpnc-fortigate-otp.patch ];
  });

  runner = writeScript "saidler-vpn-root" (
    lib.replaceStrings [ "@python@" "@vpnc@" ] [ "${python3}/bin/python3" "${vpncOtp}/bin/vpnc" ] (
      builtins.readFile ./saidler-vpn.py
    )
  );

  launcher = writeShellScriptBin "saidler-vpn" ''
    export PATH=${
      lib.makeBinPath [
        coreutils
        iproute2
        kmod
      ]
    }:/run/current-system/sw/bin
    exec ${kdePackages.konsole}/bin/konsole --separate \
      -p tabtitle="Saidler VPN" \
      -e /run/wrappers/bin/pkexec ${runner}
  '';

  desktopItem = makeDesktopItem {
    name = "saidler-vpn";
    desktopName = "Saidler VPN";
    comment = "IPsec VPN with password and email verification";
    exec = "${launcher}/bin/saidler-vpn";
    icon = "network-vpn";
    terminal = false;
    categories = [ "Network" ];
  };
in
symlinkJoin {
  name = "saidler-vpn";
  paths = [
    launcher
    desktopItem
    vpncOtp
  ];
  passthru.vpnc = vpncOtp;
}
