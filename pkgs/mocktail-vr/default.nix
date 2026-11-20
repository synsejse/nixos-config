{
  lib,
  stdenv,
  fetchFromGitHub,

  cmake,
  git,
  lld,
  ninja,
  pkg-config,
  vulkan-headers,
  makeWrapper,
  bash,

  capstone,
  curl,
  fontconfig,
  gamemode,
  glib,
  glib-networking,
  gtk4,
  hicolor-icon-theme,
  libadwaita,
  elfutils,
  libglvnd,
  libplacebo,
  libpng,
  libsecret,
  libsoup_3,
  libutf8proc,
  libyaml,
  minizip,
  nlohmann_json,
  openssl,
  sdl3,
  sdl3-ttf,
  vulkan-loader,
  webkitgtk_6_0,
  zlib,
}:
let
  src = fetchFromGitHub {
    owner = "komaruworld";
    repo = "mocktail";
    rev = "eaebb866bc04e79562a1e5416dd6aaa7568f36cb";
    fetchSubmodules = true;
    hash = "sha256-ZW/kekIQ04zBJGHhJT5X4q3CVwMA99QBaK6BoabK9ZE=";
  };
  version = "continuous-unstable-2026-11-19";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "mocktail-vr";
  inherit version;
  inherit src;
  patches = [ ./readiness-canary.patch ];

  nativeBuildInputs = [
    cmake
    git
    lld
    ninja
    pkg-config
    vulkan-headers
    makeWrapper
  ];

  buildInputs = [
    capstone
    curl
    fontconfig
    # Loaded with dlmopen at runtime. Keeping it here also adds libgamemode.so.0
    # to the wrapped binaries' and development shell's LD_LIBRARY_PATH.
    gamemode
    glib
    glib-networking
    gtk4
    hicolor-icon-theme
    libadwaita
    elfutils
    libglvnd
    libplacebo
    libpng
    libsecret
    libsoup_3
    libutf8proc
    libyaml
    minizip
    nlohmann_json
    openssl
    sdl3
    sdl3-ttf
    vulkan-loader
    webkitgtk_6_0
    zlib
  ];

  # nixpkgs installs the header we need under include/libutf8proc
  NIX_CFLAGS_COMPILE = "-I${libutf8proc}/include/libutf8proc";

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DMOCKTAIL_DEFAULT_COMPATIBILITY_MANIFEST=${placeholder "out"}/share/mocktail/metadata/roblox_compatibility.json"
    "-DMOCKTAIL_DEFAULT_SIGNING_TRUST_MANIFEST=${placeholder "out"}/share/mocktail/metadata/roblox_signing_certificates.json"
    "-DMOCKTAIL_DEFAULT_DOWNLOAD_SOURCES_MANIFEST=${placeholder "out"}/share/mocktail/metadata/roblox_download_sources.json"
    "-DBUILD_TESTING=OFF"
    "-DMOCKTAIL_ENABLE_VR=ON"
  ];

  postInstall = ''
    install -Dm644 ${finalAttrs.src}/LICENSE "$out/share/licenses/mocktail-vr/LICENSE"
    for binary in "$out/lib/mocktail/mocktail" "$out/lib/mocktail/mocktail_updater" "$out/lib/mocktail/mocktail_failure_dialog" "$out/lib/mocktail/mocktail_webview_helper" "$out/lib/mocktail/mocktail_cookie_helper" "$out/bin/mocktail-vr-probe"; do
      wrapProgram "$binary" \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath finalAttrs.buildInputs} \
        --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules" \
        --set MOCKTAIL_EGL_LIBRARY "${lib.getLib libglvnd}/lib/libEGL.so.1" \
        --set MOCKTAIL_GLES_LIBRARY "${lib.getLib libglvnd}/lib/libGLESv2.so.2" \
        --set MOCKTAIL_REQUIRE_REAL_GRAPHICS 1
    done
    rm "$out/bin/mocktail"
    substitute ${./launcher.sh} "$out/bin/mocktail-vr" \
      --subst-var-by out "$out" --subst-var-by bash "${bash}/bin/bash"
    chmod +x "$out/bin/mocktail-vr"
    rm "$out/share/applications/space.bigrat.mocktail.desktop"
    substitute ${./mocktail-vr.desktop} "$out/share/applications/space.bigrat.mocktail.vr.desktop" \
      --subst-var-by out "$out"
  '';

  meta = with lib; {
    description = "Android x86-64 Roblox compatibility runtime for Linux";
    homepage = "https://github.com/komaruworld/mocktail";
    license = licenses.asl20;
    platforms = platforms.unix;
    mainProgram = "mocktail-vr";
  };
})
