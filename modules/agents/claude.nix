{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agents.claude;
  inherit (lib) mkOption mkIf;
in
{
  options.tesujimath.agents.claude = {
    enable = mkOption {
      type = lib.types.bool;
      description = "Enable Claude Code and ACP";
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home =
      {
        packages = with pkgs; [
          claude-code
          claude-agent-acp
        ];
      };
  };
}
