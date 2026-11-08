{
  lib,
  stdenv,
  fetchurl,
  cmake,
  ninja,
  pkg-config,
  kdePackages,
  zig_0_17,
}:
let
  # Kwi needs the stable C API, newer than nixpkgs' libghostty-vt snapshot.
  ghosttyVt = stdenv.mkDerivation {
    pname = "libghostty-vt";
    version = "1.0.0";
    src = fetchurl {
      url = "https://release.files.ghostty.org/libghostty-vt/1.0.0/libghostty-vt-1.0.0.tar.gz";
      sha256 = "4a6ef758be721923e1969e7b81b443dcc92d8dd3fb5a39600c03a8817a753676";
    };
    deps = fetchurl {
      url = "https://release.files.ghostty.org/libghostty-vt/1.0.0/libghostty-vt-1.0.0-deps.tar.gz";
      sha256 = "4d5ea5e448e4c7ea8fb55ccbaa8668f2a97d44f438cee831e2b7ecd162d85c29";
    };
    nativeBuildInputs = [ zig_0_17 ];
    dontConfigure = true;
    buildPhase = ''
      runHook preBuild
      mkdir zig-packages
      tar xf "$deps" -C zig-packages --strip-components=1
      export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
      zig build --system "$PWD/zig-packages" -Doptimize=ReleaseFast -Dcpu=baseline --prefix "$out" -j$NIX_BUILD_CORES
      runHook postBuild
    '';
    dontInstall = true;
    meta.license = lib.licenses.mit;
  };
in
stdenv.mkDerivation {
  pname = "kwi";
  version = "0.1.0-unstable-2026-11-08";
  src = fetchurl {
    url = "https://invent.kde.org/utilities/kwi/-/archive/965aa31e8c7e7c2b44f7cd9d10e3f2ac730a96d8/kwi-965aa31e8c7e7c2b44f7cd9d10e3f2ac730a96d8.tar.gz";
    hash = "sha256-ZFn7VF3TipQp0/hvht745mTLJkN1dN6gHfJqNm5rJw0=";
  };
  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    kdePackages.extra-cmake-modules
    kdePackages.wrapQtAppsHook
  ];
  buildInputs = with kdePackages; [
    ghosttyVt
    qtbase
    qtdeclarative
    qtshadertools
    qtsvg
    kcoreaddons
    kconfig
    kdbusaddons
    kguiaddons
    ki18n
    kirigami
    kpty
    kio
    knotifications
    kwindowsystem
    kparts
    kxmlgui
    kwidgetsaddons
    kirigami-addons
    kirigami-app-components
    kitemmodels
    qqc2-desktop-style
  ];
  cmakeFlags = [ "-DBUILD_TESTING=OFF" ];
  meta = {
    description = "Modern terminal for KDE Plasma";
    homepage = "https://invent.kde.org/utilities/kwi";
    license = with lib.licenses; [
      gpl2Only
      gpl3Only
    ];
    platforms = lib.platforms.linux;
    mainProgram = "kwi";
  };
}
