{
  lib,
  stdenv,
  chromavenSource,
  ravenSource,
  cmake,
  ninja,
  pkg-config,
  glslang,
  wayland-scanner,
  wrapGAppsHook3,
  dbus,
  vulkan-headers,
  vulkan-loader,
  wayland,
  wayland-protocols,
  libxkbcommon,
  systemd,
  curl,
  json_c,
  libpng,
  libjpeg_turbo,
  libxml2,
  glib,
  sqlite,
  gtk3,
  libayatana-appindicator,
  libnotify,
}:

let
  # Keep local build products and IDE state out of both source trees.
  cleanSource =
    source:
    lib.cleanSourceWith {
      src = source;
      filter =
        path: type:
        let
          name = baseNameOf path;
        in
        lib.cleanSourceFilter path type
        && !(lib.elem name [
          ".idea"
          ".cache"
          "compile_commands.json"
        ])
        && !(type == "directory" && (lib.hasPrefix "build" name || lib.hasPrefix "cmake-build" name));
    };
in
stdenv.mkDerivation {
  pname = "chromaven";
  version = "0.1.0";

  src = cleanSource chromavenSource;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    glslang
    wayland-scanner
    wrapGAppsHook3
  ];
  buildInputs = [
    vulkan-headers
    vulkan-loader
    wayland
    wayland-protocols
    libxkbcommon
    systemd
    curl
    json_c
    libpng
    libjpeg_turbo
    libxml2
    glib
    sqlite
    gtk3
    libayatana-appindicator
    libnotify
  ];
  nativeCheckInputs = [ dbus ];

  cmakeBuildType = "Release";
  cmakeFlags = [
    (lib.cmakeFeature "CHROMAVEN_RAVEN_DIR" (toString (cleanSource ravenSource)))
    (lib.cmakeFeature "CHROMAVEN_SYSTEMD_USER_DIR" "lib/systemd/user")
    (lib.cmakeFeature "RAVEN_PLATFORM" "wayland")
    (lib.cmakeBool "RAVEN_FETCH_VULKAN_HEADERS" false)
    (lib.cmakeBool "RAVEN_BUILD_WEB" false)
    (lib.cmakeBool "RAVEN_BUILD_EXAMPLES" false)
    (lib.cmakeBool "RAVEN_BUILD_TESTS" false)
    (lib.cmakeBool "RAVEN_BUILD_TOOLS" false)
    (lib.cmakeBool "BUILD_TESTING" true)
  ];

  doCheck = true;

  # Install the app's packaging component, excluding Raven development files.
  installPhase = ''
    runHook preInstall
    cmake --install . --component Chromaven
    runHook postInstall
  '';

  preFixup = ''
    # Raven loads Vulkan dynamically, so ELF dependency discovery misses it.
    gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ vulkan-loader ]})
  '';

  meta = {
    description = "Native OpenRazer control panel and battery monitor";
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
    mainProgram = "chromaven";
  };
}
