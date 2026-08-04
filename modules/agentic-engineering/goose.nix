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
      default = true;
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
      in
      completions;

    home =
      {
        packages = with pkgs; [
          goose-cli
        ];
      };
  };
}
