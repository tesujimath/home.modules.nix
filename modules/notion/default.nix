{ config, pkgs, lib, ... }:

let
  cfg = config.tesujimath.notion;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.notion.cli = {
    enable = mkEnableOption "Notion CLI";
  };

  config = mkIf cfg.cli.enable {
    home.packages = [
      (pkgs.callPackage ./notion-cli-package.nix { })
    ];
  };
}
