{ pkgs, ... }:

{
  programs = {
    fish.enable = true;
    starship.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-qt;
      settings = {
        allow-preset-passphrase = "";
        # Effectively the entire login session (68 years); zero disables caching.
        default-cache-ttl = 2147483647;
        max-cache-ttl = 2147483647;
        default-cache-ttl-ssh = 2147483647;
        max-cache-ttl-ssh = 2147483647;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    python3
    btop
    fastfetch
    git
    gh
    scrcpy
    dmg2img
  ];
}
