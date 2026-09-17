{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agents.goose;
  inherit (lib) mkOption mkIf;
in
{
  options.tesujimath.agents.goose = {
    enable = mkOption {
      type = lib.types.bool;
      description = "Enable Goose agent CLI";
      default = false;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      goose-cli
    ];

    # ignored unless fish enabled
    programs.fish.completions = {
      goose.body = builtins.readFile (pkgs.runCommand "goose-fish-completion" { } ''
        ${pkgs.goose-cli}/bin/goose completion fish > $out
      '');
    };
  };
}
