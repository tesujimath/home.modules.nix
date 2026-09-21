{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agents.agent-shell-support;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.agents.agent-shell-support = {
    enable = mkEnableOption "Support for Emacs agent-shell";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      # https://github.com/xenodium/agent-shell#optional-image-utilities
      lib.optionals stdenv.hostPlatform.isDarwin [
        pngpaste
      ] ++ lib.optionals stdenv.hostPlatform.isLinux [
        imagemagick_light
        wl-clipboard
      ];
  };
}
