{ discord, vencord }:

discord.override {
  withOpenASAR = true;
  withVencord = true;
  commandLineArgs = "--disable-accelerated-video-decode";
  vencord = vencord.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      mkdir -p src/userplugins/contextTranslate
      cp -r ${./context-translate}/. src/userplugins/contextTranslate/
    '';
  });
}
