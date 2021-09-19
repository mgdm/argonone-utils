{ pkgs ? import <nixpkgs> { } }:

with pkgs;

mkShell {
  buildInputs = [
    git
    go
    gotools
    gopls
    go-outline
    gocode
    gopkgs
    gocode-gomod
    godef
    golint
  ];
}

