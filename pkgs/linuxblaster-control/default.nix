{
  lib,
  rustPlatform,
  linuxblasterSource,
  pkg-config,
  desktop-file-utils,
  udev,
  wayland,
  libxkbcommon,
  vulkan-loader,
  libGL,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
}:

let
  runtimeLibraries = [
    udev
    wayland
    libxkbcommon
    vulkan-loader
    libGL
    libx11
    libxcursor
    libxi
    libxrandr
  ];
in
rustPlatform.buildRustPackage {
  pname = "linuxblaster-control";
  version = "0.1.0";
  src = lib.cleanSource linuxblasterSource;
  cargoLock = {
    lockFile = "${linuxblasterSource}/Cargo.lock";
    outputHashes = import "${linuxblasterSource}/packaging/cargo-git-hashes.nix";
  };

  nativeBuildInputs = [
    pkg-config
    desktop-file-utils
  ];
  buildInputs = [ udev ];

  # Captured-protocol and offline UI tests; no device or display needed.
  cargoTestFlags = [ "--workspace" ];

  postInstall = ''
    install -Dm644 packaging/70-linuxblaster-control.rules $out/lib/udev/rules.d/70-linuxblaster-control.rules
    install -Dm644 packaging/linuxblaster-control.desktop $out/share/applications/linuxblaster-control.desktop
    install -Dm644 packaging/linuxblaster-control.png $out/share/icons/hicolor/256x256/apps/linuxblaster-control.png
    install -Dm644 packaging/linuxblaster-control.svg $out/share/icons/hicolor/scalable/apps/linuxblaster-control.svg
    install -Dm644 packaging/licenses/inter/LICENSE.txt $out/share/licenses/linuxblaster-control/inter/LICENSE.txt
    install -Dm644 packaging/licenses/lucide/LICENSE $out/share/licenses/linuxblaster-control/lucide/LICENSE
    desktop-file-validate $out/share/applications/linuxblaster-control.desktop
  '';

  # winit and wgpu load these with dlopen.
  postFixup = ''
    patchelf --add-rpath ${lib.makeLibraryPath runtimeLibraries} $out/bin/linuxblaster_control
  '';

  meta = {
    description = "Sound Blaster X4 output, Super X-Fi, EQ and mixer controls";
    homepage = "https://github.com/synsejse/linuxblaster_control";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "linuxblaster_control";
  };
}
