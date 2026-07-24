{ skills }:
{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agentic-engineering.claude;
  inherit (lib) mkOption mkIf;

  skillFiles = lib.attrsets.mapAttrs'
    (name: value: {
      name = ".claude/skills/${name}";
      value = value;
    })
    skills;
in
{
  options.tesujimath.agentic-engineering.claude = {
    enable = mkOption {
      type = lib.types.bool;
      description = "Enable Claude Code and ACP";
      internal = true;
      visible = false;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    home =
      {
        packages = with pkgs; [
          claude-code
          claude-agent-acp
        ];

        file = skillFiles;
      };
  };
}
