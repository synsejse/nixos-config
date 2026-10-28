{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };
  nixpkgs.config.allowUnfree = true;

  programs.nh = {
    enable = true;
    flake = "/etc/nixos";
  };
  programs.nix-ld.enable = true;
}
