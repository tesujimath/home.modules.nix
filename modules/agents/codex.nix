{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agents.codex;
  inherit (lib) mkEnableOption mkIf;

  # codex-acp tests need macOS managed preferences, which the Nix sandbox blocks
  my-codex-acp = (pkgs.codex-acp.overrideAttrs { doCheck = false; });
in
{
  options.tesujimath.agents.codex = {
    enable = mkEnableOption "Codex agent CLI";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      codex
      my-codex-acp
    ];
  };
}
