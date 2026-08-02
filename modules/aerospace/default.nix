{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.aerospace;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.aerospace = {
    enable = mkEnableOption "aerospace";
  };

  config = mkIf cfg.enable {
    home.file.".aerospace.toml".source = ./aerospace.toml;

    programs.fish.shellAbbrs = {
      bbnrs = "bb --nrepl-server";
    };
  };
}
