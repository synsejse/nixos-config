{
  discord,
  vencord,
  openasar,
  nodejs,
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
  vencord = vencord.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      mkdir -p src/userplugins/contextTranslate
      cp -r ${./context-translate}/. src/userplugins/contextTranslate/
    '';
  });
}
