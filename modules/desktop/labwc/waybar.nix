# Waybar config, templated with the launcher and session scripts.
{
  pkgs,
  launcher,
  logout,
}:

{
  layer = "top";
  position = "bottom";
  height = 40;
  spacing = 6;
  "modules-left" = [
    "custom/launcher"
    "ext/workspaces"
  ];
  "modules-center" = [ "wlr/taskbar" ];
  "modules-right" = [
    "pulseaudio"
    "network"
    "tray"
    "clock"
    "custom/session"
  ];
  "custom/launcher" = {
    format = "◉";
    "tooltip-format" = "Apps and windows · Tap Super";
    "on-click" = "${launcher}/bin/labwc-launcher";
  };
  "ext/workspaces" = {
    format = "{name}";
    "sort-by-id" = true;
    "on-click" = "activate";
  };
  "wlr/taskbar" = {
    format = "{icon}";
    "icon-size" = 23;
    "icon-theme" = "breeze-dark";
    "tooltip-format" = "{title}";
    "on-click" = "minimize-raise";
    "on-click-right" = "maximize";
    "on-click-middle" = "close";
  };
  pulseaudio = {
    format = "Vol {volume}%";
    "format-muted" = "Muted";
    "scroll-step" = 5;
    "on-click" = "easyeffects";
    "on-click-right" = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
  };
  network = {
    "format-ethernet" = "Wired";
    "format-wifi" = "Wi-Fi {signalStrength}%";
    "format-disconnected" = "Offline";
    "tooltip-format" = "{ifname}: {ipaddr}";
    "on-click" = "nm-connection-editor";
  };
  tray = {
    "icon-size" = 20;
    spacing = 10;
  };
  clock = {
    format = "{:%H:%M}";
    "tooltip-format" = "{:%A, %d %B %Y}";
  };
  "custom/session" = {
    format = "⏻";
    "tooltip-format" = "Log out · Super+Shift+E\nLock · Super+L";
    "on-click" = "${logout}/bin/labwc-logout";
    "on-click-right" = "${pkgs.swaylock}/bin/swaylock -f -c 1b1b1b";
  };
}
