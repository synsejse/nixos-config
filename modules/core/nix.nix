{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Avoid concurrent memory-heavy package builds; give each build every CPU thread.
      max-jobs = 1;
      cores = 0;
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
