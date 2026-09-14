{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.git;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.git = {
    enable = mkEnableOption "git";
  };

  config = mkIf cfg.enable {
    programs = {
      git = {
        enable = true;
        signing.format = null;
        settings = {
          user = {
            name = config.tesujimath.user.fullName;
            email = config.tesujimath.user.email;
          };
          fetch = {
            prune = true;
          };
          init = {
            defaultBranch = "main";
          };
          alias = {
            glog = "log --graph --all --pretty='format:%C(auto)%h %D %<|(100)%s %<|(120)%an %ar'";
          };
        };
      };

      gh = {
        enable = true;

        extensions = with pkgs; [
          gh-stack
        ];

        settings.aliases = {
          # preserve defaults that otherwise would be clobbered by Nix:
          co = "pr checkout";
        };
      };
    };
  };
}
