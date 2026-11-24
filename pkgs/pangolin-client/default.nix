{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  gdk-pixbuf,
  glib,
  glib-networking,
  gsettings-desktop-schemas,
  gtk3,
  libsoup_3,
  libx11,
  webkitgtk_4_1,
  xdg-utils,
}:

stdenv.mkDerivation rec {
  pname = "pangolin-client";
  version = "0.2.0";

  src = fetchurl {
    url = "https://github.com/fosrl/windows-linux/releases/download/linux-${version}/pangolin-client-amd64-${version}.deb";
    hash = "sha256-mq9bmpurBwd8azgeT1sTPkEKGkHvdWEOZTvY0/7bGE4=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = [
    gdk-pixbuf
    glib
    glib-networking
    gsettings-desktop-schemas
    gtk3
    libsoup_3
    libx11
    webkitgtk_4_1
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 usr/bin/pangolin-client "$out/bin/pangolin-client"
    install -Dm644 usr/share/applications/pangolin-client.desktop \
      "$out/share/applications/pangolin-client.desktop"
    install -Dm644 etc/xdg/autostart/pangolin-client-autostart.desktop \
      "$out/etc/xdg/autostart/pangolin-client-autostart.desktop"
    install -Dm644 usr/share/icons/hicolor/256x256/apps/pangolin-client.png \
      "$out/share/icons/hicolor/256x256/apps/pangolin-client.png"
    install -Dm644 usr/share/polkit-1/actions/net.pangolin.client.policy \
      "$out/share/polkit-1/actions/net.pangolin.client.policy"

    # Omit usr/share/pangolin-client/package-format so the in-app updater does
    # not try to invoke apt/dpkg on NixOS.
    substituteInPlace "$out/share/applications/pangolin-client.desktop" \
      --replace-fail "Exec=pangolin-client" "Exec=$out/bin/pangolin-client"
    substituteInPlace "$out/etc/xdg/autostart/pangolin-client-autostart.desktop" \
      --replace-fail "Exec=pangolin-client --autostart" "Exec=$out/bin/pangolin-client --autostart"
    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]}
    )
  '';

  meta = {
    description = "Pangolin desktop client and background tunnel service";
    homepage = "https://github.com/fosrl/windows-linux";
    license = lib.licenses.agpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "pangolin-client";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
