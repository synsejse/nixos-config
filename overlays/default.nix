{
  nixpkgs.overlays = [
    (final: prev: {
      t3code = final.callPackage ../pkgs/t3code {};
    })
  ];
}
