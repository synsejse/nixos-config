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
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libGL,
  libnotify,
  libsecret,
  libusb1,
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
  openssl,
  pango,
  systemd,
  tpm2-tss,
  zlib,
  qt6,
  xdg-utils,
  bubblewrap,
  git,
  xz,
}:

stdenv.mkDerivation rec {
  pname = "chatgpt-linux";
  version = "26.1002.52244";

  src = fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${version}_amd64.deb";
    sha256 = "9498e417131a278bce35bfff6275d252c0d332f17afc0313e0b782749f4d348a";
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
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libGL
    libnotify
    libsecret
    libusb1
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
    openssl
    pango
    systemd
    tpm2-tss
    zlib
    stdenv.cc.cc.lib
    qt6.qtbase
  ];
  runtimeDependencies = [ (lib.getLib systemd) ];
  dontWrapQtApps = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';
  dontBuild = true;
  dontConfigure = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib" "$out/bin" "$out/share"
    cp -a usr/lib/chatgpt "$out/lib/"
    # Plasma 6 uses the Qt 6 integration shim.
    rm "$out/lib/chatgpt/libqt5_shim.so"
    cp -a usr/share/applications usr/share/pixmaps "$out/share/"
    # These optional prebuilds target musl; NixOS uses the glibc variants.
    find "$out/lib/chatgpt" -name '*musl*' -prune -exec rm -rf {} +
    makeWrapper "$out/lib/chatgpt/ChatGPT" "$out/bin/chatgpt" \
      --add-flags "--ozone-platform=wayland" \
      --prefix PATH : ${
        lib.makeBinPath [
          xdg-utils
          bubblewrap
          git
          xz
        ]
      } \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          libGL
          libsecret
          libnotify
          systemd
        ]
      }
    substituteInPlace "$out/share/applications/chatgpt.desktop" \
      --replace-fail 'Exec=chatgpt ' "Exec=$out/bin/chatgpt "
    runHook postInstall
  '';

  meta = {
    description = "Official ChatGPT desktop app for Linux";
    homepage = "https://learn.chatgpt.com/docs/linux/linux-app";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "chatgpt";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
