{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agents.cursor;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.agents.cursor = {
    enable = mkEnableOption "Cursor CLI";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        cursor-cli
      ];
    };
  };
}
