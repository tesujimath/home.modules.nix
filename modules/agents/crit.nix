{ flakePkgs }:
{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agents.crit;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.agents.crit = {
    enable = mkEnableOption "Crit coding agent review tool";
  };

  config = mkIf cfg.enable {
    home.packages = [
      flakePkgs.crit
    ];
  };
}
