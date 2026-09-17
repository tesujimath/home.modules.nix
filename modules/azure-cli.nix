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

    programs = {
      # ignored unless fish is enabled
      fish.functions = {
        ado-token =
          {
            description = "Mint an Azure DevOps access token into $TOKEN";
            body = ''
              # 499b84ac-1321-427f-aa17-267ca6975798 is the fixed first-party ADO resource ID
              set -l json (az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 -o json)
              or return 1
              set -gx TOKEN (echo $json | jq -r .accessToken)
              echo "TOKEN set, expires "(echo $json | jq -r .expiresOn)
            '';
          };
        ado =
          {
            description = "GET an Azure DevOps REST URL as JSON";
            body = ''
              set -l out (curl -sS -w '\n%{http_code}' -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" $argv)
              set -l code $out[-1]
              if contains -- $code 301 302 401 403
                  echo "ado: not authenticated or not authorized (HTTP $code) - run ado-token" >&2
                  return 1
              end
              printf '%s\n' $out[1..-2]
            '';
          };
      };

    };
  };
}
