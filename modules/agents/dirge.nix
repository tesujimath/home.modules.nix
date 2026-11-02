{ flakePkgs }:
{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agents.dirge;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.agents.dirge = {
    enable = mkEnableOption "Dirge coding agent";
  };

  config = mkIf cfg.enable {
    home.packages = [
      flakePkgs.dirge
    ];
  };
}
