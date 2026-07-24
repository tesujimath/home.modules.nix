{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agentic-engineering.claude;
  inherit (lib) mkOption mkIf;
  inherit (pkgs) fetchFromGitHub;

  skills = {
    mattpocock = {
      src = fetchFromGitHub {
        owner = "mattpocock";
        repo = "skills";
        rev = "8370e760d0251a3738e006aeacec6d1cb31dd208";
        sha256 = "sha256-+Crwt+cP8B6wiIsthpwFUBgRHeTSRoPm2YASZEQE/9k=";
      };
      path = {
        # productivity
        grill-me = "skills/productivity/grill-me";
        grilling = "skills/productivity/grilling";
        handoff = "skills/productivity/handoff";
        teach = "skills/productivity/teach";
        writing-great-skills = "skills/productivity/writing-great-skills";

        # engineering
        ask-matt = "skills/engineering/ask-matt";
        codebase-design = "skills/engineering/codebase-design";
        diagnosing-bugs = "skills/engineering/diagnosing-bugs";
        domain-modeling = "skills/engineering/domain-modeling";
        grill-with-docs = "skills/engineering/grill-with-docs";
        implement = "skills/engineering/implement";
        improve-codebase-architecture = "skills/engineering/improve-codebase-architecture";
        prototype = "skills/engineering/prototype";
        resolving-merge-conflicts = "skills/engineering/resolving-merge-conflicts";
        setup-matt-pocock-skills = "skills/engineering/setup-matt-pocock-skills";
        tdd = "skills/engineering/tdd";
        to-issues = "skills/engineering/to-issues";
        to-prd = "skills/engineering/to-prd";
        triage = "skills/engineering/triage";
      };
    };

    andrej-karpathy = {
      src = fetchFromGitHub {
        owner = "multica-ai";
        repo = "andrej-karpathy-skills";
        rev = "2c606141936f1eeef17fa3043a72095b4765b9c2";
        sha256 = "sha256-4z/wRdYH7UXRzF8RJU0sw8xbpx0BW/7CBv5sVEC2knY=";
      };
      path = {
        # karpathy-guidelines = "skills/karpathy-guidelines";
      };
    };
  };

  agentsSkills = lib.concatMapAttrs
    (_: skill:
      lib.attrsets.mapAttrs'
        (name: value: {
          name = ".agents/skills/${name}";
          value = { source = "${skill.src}/${value}"; };
        })
        skill.path)
    skills;

  claudeSkills =
    if config.tesujimath.agentic-engineering.claude.enable then
      (lib.concatMapAttrs
        (_: skill:
          lib.attrsets.mapAttrs'
            (name: value: {
              name = ".claude/skills/${name}";
              value = { source = "${skill.src}/${value}"; };
            })
            skill.path)
        skills)
    else { };

in
{
  options.tesujimath.agentic-engineering.skills = {
    enable = mkOption {
      type = lib.types.bool;
      description = "Enable agents skills";
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home =
      {
        file = agentsSkills // claudeSkills;
      };
  };
}

