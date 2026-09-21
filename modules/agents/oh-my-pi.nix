{ flakePkgs }:
{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agents.oh-my-pi;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.agents.oh-my-pi = {
    enable = mkEnableOption "Oh-My-Pi agent harness";
  };

  config = mkIf cfg.enable {
    home.packages = [
      flakePkgs.oh-my-pi
    ];
  };
}
