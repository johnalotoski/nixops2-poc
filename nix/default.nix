{ sources ? import ./sources.nix, system ? __currentSystem }:
let
  pkgs = import sources.nixpkgs {};

  patches = [
    ./patches/nixpkgs-pr83548.patch
  ];

  nixpkgsNixops2 = sources.nixpkgs-nixops2;
  nixpkgsNixops2PatchedSrc = pkgs.runCommand "nixpkgs-${nixpkgsNixops2.rev}-patched" {
      inherit nixpkgsNixops2;
      inherit patches;
    } ''
    cp -r $nixpkgsNixops2 $out
    chmod -R +w $out
    for p in $patches; do
      echo "Applying patch $p";
      patch -d $out -p1 < "$p";
    done
  '';

  nixpkgsNixops2Patched = import nixpkgsNixops2PatchedSrc {};

  overlay = self: super: {
    inherit (import sources.niv { }) niv;

    nixops = (import (sources.nixops-core + "/release.nix") {
      nixpkgs = super.path;
      p = (p:
        let
          pluginSources = with sources; [ nixops-packet nixops-libvirtd ];
          plugins = map (source: p.callPackage (source + "/release.nix") { })
            pluginSources;
        in [ p.aws ] ++ plugins);
    }).build.${system};

    nixops2 = nixpkgsNixops2Patched.nixops2Unstable.withPlugins (ps: with ps; [
      nixops-aws
      nixops-virtd
      nixops-encrypted-links
      nixops-gcp
      nixopsvbox
    ]);
  };

in import sources.nixpkgs {
  overlays = [ overlay ];
  inherit system;
  config = { };
}
