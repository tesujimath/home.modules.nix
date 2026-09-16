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
      default =
        let
          # latest version required to list pipelines 🤷
          azure-devops = pkgs.azure-cli-extensions.azure-devops.overridePythonAttrs (_: rec {
            version = "1.0.8";
            src = pkgs.fetchurl {
              url = "https://github.com/Azure/azure-cli-extensions/releases/download/azure-devops-${version}/azure_devops-${version}-py2.py3-none-any.whl";
              hash = "sha256-uQzJx2TLZrBj6LXUBxY/PnqUS7UM9d18SC9K4Zj5Nk4=";
            };
          });
        in
        [
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
