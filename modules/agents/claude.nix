{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agents.claude;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.agents.claude = {
    enable = mkEnableOption "Claude Code and its ACP";
  };

  config = mkIf cfg.enable {
    tesujimath.agents.skills.targets = [ ".claude/skills" ];

    home =
      {
        packages = with pkgs; [
          claude-code
          claude-agent-acp
        ];
      };
  };
}
