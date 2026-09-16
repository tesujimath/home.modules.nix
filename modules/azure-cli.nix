{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.azure-cli;
  inherit (lib) mkEnableOption mkIf mkOption;
in
{
  options.tesujimath.azure-cli = {
    enable = mkEnableOption "azure-cli";
    extensions = mkOption {
      type = lib.types.listOf lib.types.package;
      description = "Azure-CLI extension to install";
      default = with pkgs.azure-cli-extensions; [
        azure-devops
      ];
    };

  };

  config = mkIf cfg.enable {
    home.packages =
      let
        azure-cli-with-extensions = pkgs.azure-cli.override {
          withExtensions = cfg.extensions;
        };
      in
      [
        azure-cli-with-extensions
      ];
  };
}
