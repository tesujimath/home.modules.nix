{ config, lib, ... }:

let
  cfg = config.tesujimath.zsh;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.zsh = {
    enable = mkEnableOption "zsh";
  };

  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;

      envExtra = ''
        ${if config.tesujimath.homebrew.enable then ''

          # homebrew integration
          eval "$(/opt/homebrew/bin/brew shellenv)"
        '' else ""}
      '';

      initContent = ''
        home-manager-switch() {
          if test -n "$HOME_MANAGER_FLAKE_REF_ATTR"; then
            home-manager switch -v --flake $HOME_MANAGER_FLAKE_REF_ATTR "$@"

            unset __HM_SESS_VARS_SOURCED
            . $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
            . $HOME/.zshrc
          else
            echo >&2 error: missing environment variable HOME_MANAGER_FLAKE_REF_ATTR
          fi
        }

        home-manager-switch-with-local-tesujimath-modules() {
          home-manager-switch --override-input tesujimath-modules "''${HOME_MANAGER_FLAKE_REF_ATTR%/home.nix*}/home.modules.nix"
        }
      '';

      profileExtra = ''

        # OrbStack integration
        source ~/.orbstack/shell/init.zsh 2>/dev/null || :
      '';
    };
  };
}
