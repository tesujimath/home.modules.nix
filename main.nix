{ flakePkgsForSystem }:
{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption types;
  flakePkgs = flakePkgsForSystem pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    ./modules/agentic-engineering.nix
    ./modules/babashka.nix
    ./modules/bash.nix
    ./modules/carapace.nix
    ./modules/emacs.nix
    (import ./modules/fish { inherit flakePkgs; })
    ./modules/fonts.nix
    ./modules/git
    ./modules/spacehammer
    ./modules/helix.nix
    ./modules/homebrew.nix
    (import ./modules/languages { inherit flakePkgs; })
    ./modules/mitmproxy
    ./modules/syncthing.nix
    ./modules/web-browser.nix
    ./modules/wezterm
    ./modules/xdg.nix
    ./modules/xmonad-desktop
    ./modules/yazi
    ./modules/zathura.nix
    ./modules/zed-editor.nix
    ./modules/zsh.nix
  ];

  options.tesujimath.defaultShell = mkOption { default = "bash"; type = types.str; description = "Default shell"; };
  options.tesujimath.defaultShellPath = mkOption { default = "${pkgs.bash}/bin/bash"; type = types.str; description = "Absolute path of default shell"; };
  options.tesujimath.defaultEditor = mkOption { default = "vi"; type = types.str; description = "Default editor"; };
  options.tesujimath.user =
    {
      email = mkOption { type = types.str; description = "Email address"; };
      fullName = mkOption { type = types.str; description = "Full name"; };
    };

  config = {
    home = {
      sessionVariables = {
        EMAIL = config.tesujimath.user.email;
        EDITOR = config.tesujimath.defaultEditor;
      };
    };

    programs = {
      # Let Home Manager install and manage itself.
      home-manager.enable = true;

      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };

    # additional docs, access via home-manager-help command
    manual.html.enable = true;
  };
}
