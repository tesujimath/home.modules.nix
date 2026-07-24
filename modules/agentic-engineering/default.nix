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
        opencode
        qwen-code
      ];
    };
  };

  imports = [
    ./claude.nix
    ./goose.nix
    ./skills.nix
  ];
}
