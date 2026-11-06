{
  discord,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs,
  openasar,
  pnpm_11,
  vencord,
}:

discord.override {
  withOpenASAR = true;
  withVencord = true;
  commandLineArgs = "--disable-accelerated-video-decode";
  openasar = openasar.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./openasar-read-only-modules.patch ];
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      ${nodejs}/bin/node ${./test-openasar-updater.cjs} src/updater/moduleUpdater.js
      runHook postCheck
    '';
  });
  # Discord's rspack update breaks startup with nixpkgs' 1.15.13.
  vencord = vencord.overrideAttrs (
    finalAttrs: _: {
      version = "1.15.16";
      # nixpkgs' lockfile fixes target 1.15.13; 1.15.16 has aligned React types.
      patches = [ ];
      postPatch = "";
      src = fetchFromGitHub {
        owner = "Vendicated";
        repo = "Vencord";
        tag = "v${finalAttrs.version}";
        hash = "sha256-aUJubLJpyLAZWiOezqFxPY6oVPgWVPQpajFqrJvrO9U=";
      };
      pnpmDeps = fetchPnpmDeps {
        inherit (finalAttrs)
          pname
          src
          patches
          postPatch
          ;
        pnpm = pnpm_11;
        fetcherVersion = 4;
        hash = "sha256-HS8uZNepvDefjrsG3buVLFCVv7sHvazcwdpcT3EQ/78=";
      };
    }
  );
}
