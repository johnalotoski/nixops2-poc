with { pkgs = import ./nix { }; };
let
  nixops2Wrapped = pkgs.runCommand "nixops2" {
      buildInputs = [ pkgs.makeWrapper ];
    } ''
    mkdir $out
    ln -s ${pkgs.nixops2}/* $out
    rm $out/bin
    mkdir $out/bin
    ln -s ${pkgs.nixops2}/bin/* $out/bin
    rm $out/bin/nixops
    makeWrapper ${pkgs.nixops2}/bin/nixops $out/bin/nixops2
  '';
in pkgs.mkShell {
  buildInputs = with pkgs; [
    niv
    nixops
    nixops2Wrapped
  ];
  shellHook = ''
    unset PYTHONPATH
    echo "nixops1 => ${pkgs.nixops}"
    echo "nixops2 => ${pkgs.nixops2}"
  '';
}
