{ config, lib, ... }:

let
  cfg = config.tesujimath.homebrew;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.homebrew = {
    enable = mkEnableOption "homebrew";
  };

  config = mkIf cfg.enable {
    programs = {
      # ignored unless fish enabled
      fish.interactiveShellInit = ''

          # homebrew integration
          eval "$(/opt/homebrew/bin/brew shellenv)"
      '';

      # ignored unless zsh enabled
      zsh.envExtra = ''
        # homebrew integration
        eval "$(/opt/homebrew/bin/brew shellenv)"
      '';
    };
  };
}
