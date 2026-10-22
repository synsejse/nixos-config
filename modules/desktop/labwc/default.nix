{
  config,
  lib,
  pkgs,
  ...
}:

let
  wallpaper = "${config.users.users.synse.home}/Pictures/Wallpapers/wallhaven-1qx59v.jpg";

  launcher = pkgs.writeShellScriptBin "labwc-launcher" ''
    exec ${pkgs.rofi}/bin/rofi -config "''${LABWC_LAUNCHER_CONFIG:-/etc/xdg/labwc/launcher.rasi}" -show "''${1:-combi}"
  '';
  logout = pkgs.writeShellScriptBin "labwc-logout" ''
    choice=$(printf 'Cancel\nLog out\n' | ${pkgs.rofi}/bin/rofi \
      -config "''${LABWC_LAUNCHER_CONFIG:-/etc/xdg/labwc/launcher.rasi}" \
      -dmenu -p 'Log out of labwc?' -no-custom \
      -theme-str 'entry { placeholder: "Log out of labwc?"; }' \
      -theme-str 'listview { lines: 2; } textbox-hint { enabled: false; }')
    if [ "$choice" = 'Log out' ]; then
      exec ${pkgs.labwc}/bin/labwc --exit
    fi
  '';
  # Tell NixOS's session wrapper that our autostart handles systemd integration.
  session = pkgs.symlinkJoin {
    name = "labwc-session";
    paths = [ pkgs.labwc ];
    postBuild = ''
      rm "$out/share/wayland-sessions/labwc.desktop"
      cp ${pkgs.writeText "labwc.desktop" ''
        [Desktop Entry]
        Name=labwc
        Comment=Floating Wayland desktop
        Exec=${pkgs.labwc}/bin/labwc
        Icon=labwc
        Type=Application
        DesktopNames=labwc;wlroots;X-NIXOS-SYSTEMD-AWARE
      ''} "$out/share/wayland-sessions/labwc.desktop"
    '';
    passthru.providedSessions = [ "labwc" ];
  };
  sessionService = description: command: {
    inherit description;
    path = [
      "%h/.local"
      "/run/current-system/sw"
      "/etc/profiles/per-user/%u"
    ];
    wantedBy = [ "labwc-session.target" ];
    partOf = [ "labwc-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = command;
      Restart = "on-failure";
    };
  };
in
{
  programs.labwc = {
    enable = true;
    package = session;
  };
  services.displayManager.defaultSession = "labwc";

  environment.systemPackages = with pkgs; [
    launcher
    logout
    waybar
    rofi
    kanshi
    wlr-randr
    mako
    swaybg
    swaylock
    swayidle
    grim
    wl-clipboard
    networkmanagerapplet
  ];
  fonts.packages = [ pkgs.open-sans ];

  xdg.portal.config.labwc = {
    default = [ "gtk" ];
    "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
    "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
    "org.freedesktop.impl.portal.Inhibit" = [ "none" ];
  };

  systemd.user.targets.labwc-session = {
    description = "labwc session";
    bindsTo = [ "graphical-session.target" ];
    wants = [
      "graphical-session-pre.target"
      "xdg-desktop-autostart.target"
    ];
    after = [ "graphical-session-pre.target" ];
  };

  environment.etc = {
    "xdg/labwc/environment".text = ''
      WLR_RENDERER=vulkan
      XDG_CURRENT_DESKTOP=labwc:wlroots
      XDG_SESSION_DESKTOP=labwc
      XDG_SESSION_TYPE=wayland
      XKB_DEFAULT_LAYOUT=us
      XCURSOR_THEME=breeze_cursors
      XCURSOR_SIZE=24
      QT_QPA_PLATFORMTHEME=kde
      QT_QPA_PLATFORM=wayland;xcb
      QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      _JAVA_AWT_WM_NONREPARENTING=1
    '';

    "xdg/labwc/autostart".source = pkgs.writeShellScript "labwc-autostart" ''
      # Import PATH as well so D-Bus-activated Ghostty sees ~/.local/bin/codex.
      ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
        DISPLAY WAYLAND_DISPLAY PATH XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP \
        XDG_SESSION_TYPE XCURSOR_THEME XCURSOR_SIZE QT_QPA_PLATFORMTHEME \
        QT_QPA_PLATFORM QT_WAYLAND_DISABLE_WINDOWDECORATION
      ${pkgs.systemd}/bin/systemctl --user start labwc-session.target
    '';

    "xdg/labwc/shutdown".source = pkgs.writeShellScript "labwc-shutdown" ''
      ${pkgs.systemd}/bin/systemctl --user stop graphical-session.target
    '';

    "xdg/labwc/rc.xml".text = import ./rc.nix {
      inherit
        lib
        pkgs
        launcher
        logout
        ;
    };
    "xdg/labwc/themerc-override".source = ./themerc-override;
    "xdg/labwc/kanshi.conf".source = ./kanshi.conf;
    "xdg/labwc/launcher.rasi".source = ./launcher.rasi;
    "xdg/labwc/waybar.json".source = pkgs.writeText "labwc-waybar.json" (
      builtins.toJSON (import ./waybar.nix { inherit pkgs launcher logout; })
    );
    "xdg/labwc/waybar.css".source = ./waybar.css;
    "xdg/labwc/mako.conf".source = ./mako.conf;
  };

  systemd.user.services = {
    labwc-waybar = sessionService "labwc taskbar" "${pkgs.waybar}/bin/waybar -c /etc/xdg/labwc/waybar.json -s /etc/xdg/labwc/waybar.css";
    labwc-mako = sessionService "labwc notifications" "${pkgs.mako}/bin/mako --config /etc/xdg/labwc/mako.conf";
    labwc-kanshi = sessionService "labwc display layout" "${pkgs.kanshi}/bin/kanshi -c /etc/xdg/labwc/kanshi.conf";
    labwc-background = sessionService "labwc wallpaper" "${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill";
    labwc-sleep-lock = sessionService "Lock labwc before suspend" "${pkgs.swayidle}/bin/swayidle -w before-sleep '${pkgs.swaylock}/bin/swaylock -f -c 1b1b1b'";
    labwc-polkit-agent =
      (sessionService "labwc authentication agent" "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1")
      // {
        environment.QT_QPA_PLATFORMTHEME = "kde";
      };
  };
}
