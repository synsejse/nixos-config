{
  callPackage,
  lib,
  glib-networking,
  libglvnd,
  mocktailSource,
}:

# Upstream's package only wraps bin/mocktail, a second copy of the runtime that
# cannot find the helpers installed beside the one in lib/mocktail.
(callPackage "${mocktailSource}/packaging/nix/package.nix" { }).overrideAttrs (
  finalAttrs: _: {
    postInstall = ''
      for binary in mocktail mocktail_updater mocktail_failure_dialog mocktail_webview_helper mocktail_cookie_helper; do
        wrapProgram "$out/lib/mocktail/$binary" \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath finalAttrs.buildInputs} \
          --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules" \
          --set MOCKTAIL_EGL_LIBRARY "${lib.getLib libglvnd}/lib/libEGL.so.1" \
          --set MOCKTAIL_GLES_LIBRARY "${lib.getLib libglvnd}/lib/libGLESv2.so.2" \
          --set MOCKTAIL_REQUIRE_REAL_GRAPHICS 1
      done
      ln -sf "$out/lib/mocktail/mocktail" "$out/bin/mocktail"
      substituteInPlace "$out/share/applications/space.bigrat.mocktail.desktop" \
        --replace-fail 'Exec=mocktail %u' "Exec=$out/bin/mocktail %u"
    '';
  }
)
