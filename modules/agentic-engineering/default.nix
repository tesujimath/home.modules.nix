{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agentic-engineering;
  inherit (lib) mkEnableOption mkIf;
  skills = import ./skills.nix { inherit lib pkgs; };
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
        opencode
        qwen-code
      ];
    };

    # internal modules
    tesujimath.agentic-engineering = {
      claude.enable = true;
      goose.enable = true;
    };
  };

  imports = [
    (import ./claude.nix { inherit skills; })
    ./goose.nix
  ];
}
