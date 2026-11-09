{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  desktop-file-utils,
  expat,
  glib,
  gtk3,
  libgbm,
  libGL,
  libnotify,
  libsecret,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  nspr,
  nss,
  pango,
  systemd,
  xdg-utils,
  git,
  android-device-sdk,
  nodejs_24,
}:

stdenv.mkDerivation rec {
  pname = "t3code";
  version = "0.1.8-nightly.20261109.4399";

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-amd64.deb";
    hash = "sha256-+ODyncLWmKXhqQB9fBfX8fcMz9/9GzScLpGOyqMdC2w=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libgbm
    libnotify
    libsecret
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    pango
    systemd
    stdenv.cc.cc.lib
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
    mkdir -p "$out/lib" "$out/bin" "$out/share"
    cp -a "opt/T3 Code (Nightly)" "$out/lib/t3code"
    cp -a usr/share/applications usr/share/icons "$out/share/"
    # Keep the glibc native modules used on this x86_64 NixOS host.
    find "$out/lib/t3code" -name '*musl*' -prune -exec rm -rf {} +
    rm -rf "$out/lib/t3code/resources/app.asar.unpacked/node_modules/node-pty/prebuilds/linux-arm64"
    makeWrapper "$out/lib/t3code/t3code" "$out/bin/t3code" \
      --add-flags "--ozone-platform=wayland" \
      --set T3CODE_DISABLE_AUTO_UPDATE true \
      --set T3CODE_DESKTOP_LAUNCHER_PATH "$out/bin/t3code" \
      --set ANDROID_HOME "${android-device-sdk}/libexec/android-sdk" \
      --set ANDROID_SDK_ROOT "${android-device-sdk}/libexec/android-sdk" \
      --prefix PATH : ${
        lib.makeBinPath [
          xdg-utils
          git
          desktop-file-utils
          android-device-sdk
          nodejs_24
        ]
      } \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          libGL
          libnotify
          libsecret
          systemd
        ]
      }
    substituteInPlace "$out/share/applications/t3code.desktop" \
      --replace-fail 'Exec="/opt/T3 Code (Nightly)/t3code"' "Exec=$out/bin/t3code"
    runHook postInstall
  '';

  meta = {
    description = "T3 Code desktop app for coding agents";
    homepage = "https://github.com/pingdotgg/t3code";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "t3code";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
