{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agentic-engineering.goose;
  inherit (lib) mkOption mkIf;
in
{
  options.tesujimath.agentic-engineering.goose = {
    enable = mkOption {
      type = lib.types.bool;
      description = "Enable Goose agent CLI";
      internal = true;
      visible = false;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile =
      let
        completions =
          if config.tesujimath.fish.enable then {
            "fish/completions/goose.fish".source =
              pkgs.runCommand "goose-fish-completion" { } ''
                ${pkgs.goose-cli}/bin/goose completion fish > $out
              '';
          } else { };

        providers = {
          "goose/custom_providers/oMLX.json".text = builtins.toJSON {
            name = "oMLX";
            engine = "openai";
            display_name = "Local oMLX";
            description = "oMLX running on localhost";
            base_url = "http://localhost:8000/v1";
            models = [
              {
                name = "Devstral-Small-2-24B-Instruct-2512-4bit";
                context_limit = 393216;
              }
              {
                name = "Ornith-1.0-9B-4bit";
                context_limit = 262144;
              }
              {
                name = "Ornith-1.0-35B-5bit-XL-mlx";
                context_limit = 262144;
              }
              {
                name = "Qwen3.6-27B-MLX-4bit";
                context_limit = 262144;
              }
            ];
          };
        };
      in
      completions // providers;

    home =
      {
        packages = with pkgs; [
          goose-cli
        ];

        sessionVariables = {
          GOOSE_PROVIDER = "oMLX";
          GOOSE_MODEL = "Ornith-1.0-9B-4bit";
        };
      };
  };
}
