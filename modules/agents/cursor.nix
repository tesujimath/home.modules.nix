{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agents.cursor;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.agents.cursor = {
    enable = mkEnableOption "Cursor and its ACP";
  };

  config = mkIf cfg.enable {
    programs = {
      cursor.enable = true;
    };

    home = {
      packages = with pkgs; [
        cursor-cli
      ];
    };
  };
}
