{ androidenv, symlinkJoin }:

let
  sdk =
    (androidenv.composeAndroidPackages {
      includeEmulator = true;
      includeSystemImages = false;
      platformVersions = [ ];
      buildToolsVersions = [ ];
    }).androidsdk;
in
symlinkJoin {
  name = "android-device-sdk";
  paths = [ sdk ];
  # T3 requires the standard latest alias; nixpkgs uses a versioned directory.
  postBuild = ''
    cd "$out/libexec/android-sdk/cmdline-tools"
    if [ ! -e latest ]; then
      ln -s "$(ls -d [0-9]* | sort -V | tail -n 1)" latest
    fi
  '';
}
