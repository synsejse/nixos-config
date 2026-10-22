# labwc rc.xml, templated with store paths and generated desktop keybinds.
{
  lib,
  pkgs,
  launcher,
  logout,
}:

''
  <?xml version="1.0"?>
  <labwc_config>
    <core>
      <decoration>server</decoration>
      <adaptiveSync>yes</adaptiveSync>
      <allowTearing>fullscreenForced</allowTearing>
      <hdr>yes</hdr>
      <gap>0</gap>
    </core>
    <theme>
      <icon>breeze-dark</icon>
      <titlebar><layout>icon:iconify,max,close</layout></titlebar>
      <cornerRadius>8</cornerRadius>
      <dropShadows>yes</dropShadows>
      <maximizedDecoration>titlebar</maximizedDecoration>
      <font><name>Open Sans</name><size>10</size></font>
    </theme>
    <focus><followMouse>no</followMouse></focus>
    <windowSwitcher preview="yes" outlines="yes" order="focus">
      <osd show="yes" style="classic" output="focused" />
      <fields>
        <field content="icon" width="7%" />
        <field content="title" width="93%" />
      </fields>
    </windowSwitcher>
    <desktops number="10" popupTime="500" prefix="" />
    <keyboard>
      <default />
      <repeatDelay>600</repeatDelay>
      <repeatRate>25</repeatRate>
      <keybind key="Super_L" onRelease="yes">
        <action name="Execute" command="${launcher}/bin/labwc-launcher" />
      </keybind>
      <keybind key="Super_R" onRelease="yes">
        <action name="Execute" command="${launcher}/bin/labwc-launcher" />
      </keybind>
      <keybind key="W-d"><action name="Execute" command="${launcher}/bin/labwc-launcher" /></keybind>
      <keybind key="W-Return"><action name="Execute" command="ghostty" /></keybind>
      <keybind key="W-S-q"><action name="Close" /></keybind>
      <keybind key="W-f"><action name="ToggleFullscreen" /></keybind>
      <keybind key="W-a"><action name="ToggleMaximize" /></keybind>
      <keybind key="W-m"><action name="Iconify" /></keybind>
      <keybind key="W-S-d"><action name="ToggleShowDesktop" /></keybind>
      <keybind key="W-S-c"><action name="Reconfigure" /></keybind>
      <keybind key="W-S-e"><action name="Execute" command="${logout}/bin/labwc-logout" /></keybind>
      <keybind key="W-l"><action name="Execute" command="${pkgs.swaylock}/bin/swaylock -f -c 1b1b1b" /></keybind>
      ${lib.concatMapStringsSep "\n" (
        n:
        let
          key = if n == 10 then "0" else toString n;
        in
        ''
          <keybind key="W-${key}"><action name="GoToDesktop" to="${toString n}" /></keybind>
          <keybind key="W-S-${key}"><action name="SendToDesktop" to="${toString n}" follow="no" /></keybind>
        ''
      ) (lib.range 1 10)}
      <keybind key="XF86AudioRaiseVolume" allowWhenLocked="yes"><action name="Execute" command="wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+" /></keybind>
      <keybind key="XF86AudioLowerVolume" allowWhenLocked="yes"><action name="Execute" command="wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" /></keybind>
      <keybind key="XF86AudioMute" allowWhenLocked="yes"><action name="Execute" command="wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" /></keybind>
      <keybind key="XF86AudioMicMute" allowWhenLocked="yes"><action name="Execute" command="wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" /></keybind>
      <keybind key="Print"><action name="Execute" command="sh -c '${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy --type image/png'" /></keybind>
    </keyboard>
    <!-- Default bindings include titlebar buttons, double-click maximize,
         Super+left-drag move and Super+right-drag resize. -->
    <mouse><default /></mouse>
    <libinput>
      <device category="non-touch">
        <accelProfile>flat</accelProfile>
        <pointerSpeed>-0.4</pointerSpeed>
      </device>
    </libinput>
  </labwc_config>
''
