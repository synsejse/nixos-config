{ pkgs, ... }: {
  programs.fish.enable = true;
  programs.starship.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-qt;
  };
  environment.systemPackages = with pkgs; [
    python3 btop fastfetch git gh curl wget ripgrep fd jq
  ];
}
