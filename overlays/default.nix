{ lib }:

rec {
  nuspell = import ./nuspell.nix;

  default = lib.composeManyExtensions [
    nuspell
  ];
}
