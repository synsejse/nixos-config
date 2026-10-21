# Saidler IPsec IKEv1 VPN: PSK + XAuth password + email OTP.
# /etc/vpnc/saidler.conf holds the gateway, username, PSK, and DH14 settings.
# VPN and mailbox passwords are read at runtime from ~/.config/saidler-vpn/
# password and mail-password respectively; neither is stored in the Nix store.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vpnc
    (let
      vpnRunner = writeScript "saidler-vpn-root" (
        lib.replaceStrings
          [ "@python@" "@vpnc@" ]
          [ "${python3}/bin/python3" "${vpnc}/bin/vpnc" ]
          (builtins.readFile ./saidler-vpn.py)
      );
    in writeShellScriptBin "saidler-vpn" ''
      export PATH=${lib.makeBinPath [ coreutils iproute2 kmod ]}:/run/current-system/sw/bin
      exec ${kdePackages.konsole}/bin/konsole --separate \
        -p tabtitle="Saidler VPN" \
        -e /run/wrappers/bin/pkexec ${vpnRunner}
    '')
    (makeDesktopItem {
      name = "saidler-vpn";
      desktopName = "Saidler VPN";
      comment = "IPsec VPN with password and email verification";
      exec = "/run/current-system/sw/bin/saidler-vpn";
      icon = "network-vpn";
      terminal = false;
      categories = [ "Network" ];
    })
  ];
}
