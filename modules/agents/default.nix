{ flakePkgs }:
{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agents;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.agents = {
    enable = mkEnableOption "agents";
  };

  config = mkIf cfg.enable {
    programs = {
      cursor.enable = true;
    };

    home = {
      packages = with pkgs; [
        cursor-cli
        # beads
        # opencode
      ];
    };
  };

  imports = [
    ./agent-shell-support.nix
    ./claude.nix
    ./deprecated.nix
    ./goose.nix
    ./skills.nix
    (import ./oh-my-pi.nix { inherit flakePkgs; })
  ];
}
