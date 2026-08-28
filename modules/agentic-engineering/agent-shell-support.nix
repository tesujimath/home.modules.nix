{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agentic-engineering.agent-shell-support;
  inherit (lib) mkOption mkIf;
in
{
  options.tesujimath.agentic-engineering.agent-shell-support = {
    enable = mkOption {
      type = lib.types.bool;
      description = "Enable support for Emacs agent-shell";
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      # https://github.com/xenodium/agent-shell#optional-image-utilities
      lib.optionals stdenv.isDarwin [
        pngpaste
      ] ++ lib.optionals stdenv.isLinux [
        imagemagick_light
        wl-clipboard
      ];
  };
}
