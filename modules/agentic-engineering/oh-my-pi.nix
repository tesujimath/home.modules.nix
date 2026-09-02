{ flakePkgs }:
{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agentic-engineering.oh-my-pi;
  inherit (lib) mkOption mkIf;
in
{
  options.tesujimath.agentic-engineering.oh-my-pi = {
    enable = mkOption {
      type = lib.types.bool;
      description = "Enable Oh-My-Pi agent harness";
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      flakePkgs.oh-my-pi
    ];
  };
}
