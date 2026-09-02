{ flakePkgs }:
{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agentic-engineering;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.agentic-engineering = {
    enable = mkEnableOption "agentic-engineering";
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
    ./goose.nix
    ./skills.nix
    (import ./oh-my-pi.nix { inherit flakePkgs; })
  ];
}
