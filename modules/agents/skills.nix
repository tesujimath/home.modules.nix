{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agents;
  inherit (lib) mkOption mkIf mkDefault types;
  inherit (pkgs) fetchFromGitHub;

  sourceModule = { config, ... }: {
    options = {
      enable = mkOption {
        type = types.bool;
        description = "Whether to install skills from this source";
        default = true;
      };

      owner = mkOption {
        type = types.nullOr types.str;
        description = "GitHub owner, used to derive `src`";
        default = null;
      };

      repo = mkOption {
        type = types.nullOr types.str;
        description = "GitHub repo, used to derive `src`";
        default = null;
      };

      rev = mkOption {
        type = types.nullOr types.str;
        description = "GitHub revision, used to derive `src`";
        default = null;
      };

      hash = mkOption {
        type = types.nullOr types.str;
        description = "Hash of the fetched source, used to derive `src`";
        default = null;
      };

      src = mkOption {
        type = types.path;
        description = ''
          The tree containing the skills.  Derived from `owner`, `repo`, `rev` and `hash`
          when those are set, but may be overridden with any path, such as a local checkout
          or a different fetcher.
        '';
      };

      skills = mkOption {
        type = types.attrsOf types.str;
        description = ''
          Skills to install from this source, mapping the installed skill name to its
          path within `src`.  The installed name need not be the basename of the path,
          which allows renaming to avoid collisions between sources.
        '';
        default = { };
        example = lib.literalExpression ''
          {
            handoff = "skills/productivity/handoff";
            implement = "skills/engineering/implement";
          }
        '';
      };
    };

    config.src = mkIf (config.owner != null) (mkDefault (fetchFromGitHub {
      inherit (config) owner repo rev hash;
    }));
  };

  enabledSources = lib.filterAttrs (_: source: source.enable) cfg.skills.sources;

  # flattened across all enabled sources, one element per skill to install
  selected = lib.concatLists (lib.mapAttrsToList
    (sourceName: source:
      lib.mapAttrsToList
        (skillName: path: {
          inherit sourceName skillName;
          source = "${source.src}/${path}";
        })
        source.skills)
    enabledSources);

  # a skill name may be claimed by at most one source
  duplicated = lib.filterAttrs (_: claimants: lib.length claimants > 1)
    (lib.groupBy (skill: skill.skillName) selected);

  duplicateMessages = lib.mapAttrsToList
    (skillName: claimants:
      "${skillName} (from ${lib.concatStringsSep ", " (map (skill: skill.sourceName) claimants)})")
    duplicated;

  skillFiles = lib.listToAttrs (lib.concatMap
    (target: map
      (skill: lib.nameValuePair "${target}/${skill.skillName}" { inherit (skill) source; })
      selected)
    (lib.unique cfg.skills.targets));

in
{
  options.tesujimath.agents.skills = {
    enable = mkOption {
      type = types.bool;
      description = "Enable agents skills";
      default = false;
    };

    targets = mkOption {
      type = types.listOf types.str;
      description = ''
        Directories relative to `$HOME` into which every selected skill is installed.
        Modules for individual agents contribute their own directories, and definitions
        from all modules are concatenated, so replacing this list wholesale requires
        `lib.mkForce`.
      '';
      default = [ ];
      example = lib.literalExpression ''[ ".agents/skills" ]'';
    };

    sources = mkOption {
      type = types.attrsOf (types.submodule sourceModule);
      description = ''
        Sources of skills.  Predefined sources may be disabled, have their revision bumped,
        or have their selection of skills replaced, and further sources may be added.
      '';
      default = { };
      example = lib.literalExpression ''
        {
          smartly-skills = {
            owner = "Smartly-NZ";
            repo = "Skills";
            rev = "4449c9bc049c2f5fb0e0483c36a8e8df00947e25";
            hash = lib.fakeHash;
            skills.direnv = "direnv";
          };
        }
      '';
    };
  };

  config = lib.mkMerge [
    {
      tesujimath.agents.skills = {
        targets = [ ".agents/skills" ];

        sources = {
          mattpocock = {
            owner = mkDefault "mattpocock";
            repo = mkDefault "skills";
            rev = mkDefault "8370e760d0251a3738e006aeacec6d1cb31dd208";
            hash = mkDefault "sha256-+Crwt+cP8B6wiIsthpwFUBgRHeTSRoPm2YASZEQE/9k=";
            skills = mkDefault {
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

          gh-stack = {
            # v0.1.1 - the skill was rewritten here, much leaner than v0.1.0's
            owner = mkDefault "github";
            repo = mkDefault "gh-stack";
            rev = mkDefault "2bd699a544a09cb5c45a013d03416e0894b0454e";
            hash = mkDefault "sha256-jwfqiCnCOOW0AKA52hbgvCCoLzfFX+QfM+vXABkzZgw=";
            skills = mkDefault {
              gh-stack = "skills/gh-stack";
            };
          };

          andrej-karpathy = {
            owner = mkDefault "multica-ai";
            repo = mkDefault "andrej-karpathy-skills";
            rev = mkDefault "2c606141936f1eeef17fa3043a72095b4765b9c2";
            hash = mkDefault "sha256-4z/wRdYH7UXRzF8RJU0sw8xbpx0BW/7CBv5sVEC2knY=";
            skills = mkDefault {
              # karpathy-guidelines = "skills/karpathy-guidelines";
            };
          };
        };
      };
    }

    (mkIf cfg.skills.enable {
      assertions = [{
        assertion = duplicated == { };
        message = ''
          tesujimath.agents.skills: skill names claimed by more than one source: ${lib.concatStringsSep "; " duplicateMessages}.
          Rename or deselect one of them in the relevant source's `skills` attrset.
        '';
      }];

      home.file = skillFiles;
    })
  ];
}
