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
          plugins = map (source: p.callPackage (source + "/release.nix") {})
            pluginSources;
        in [ p.aws ] ++ plugins);
    }).build.${system};

    nixops2 = let
      nixops-digitalocean = pkgs.fetchgit {
        url = "https://github.com/Kiwi/nixops-digitalocean.git";
        rev = "8fe2f274d9b14c6e90c02645d20e12f7f911e0e5";
        sha256 = "1l0wfq4wj6wcc8dpxa424zh1x8acmbw1k3wnb27a87ghfbanpbic";
      };
      overrides = self: super: {
        # Required to avoid nixops and charon python build collision failure
        # Default priority is 5; lower number is higher priority
        nixops = super.nixops.overridePythonAttrs (
          old: {
            meta = old.meta // { priority = 4; };
          }
        );
        nixops-packet = let
          nixops-packet = self.callPackage ../../nixops-packet {};
        in nixops-packet.overridePythonAttrs (
          old: {
            # Addnl overrides here
          }
        );
      };
    in (nixpkgsNixops2Patched.nixops2Unstable.override { inherit overrides; }).withPlugins (ps: with ps; [
      nixops-aws
      nixops-virtd
      nixops-encrypted-links
      nixops-gcp
      nixopsvbox
      nixops-packet                         # Example local repo, with optional attr overrides above;
                                            # urllib3 version was adjusted in nixops-packet locally to match urllib3 version in gcp to avoid collision fail
      (callPackage nixops-digitalocean {})  # Example fetchgit repo
    ]);
  };

in import sources.nixpkgs {
  overlays = [ overlay ];
  inherit system;
  config = { };
}
