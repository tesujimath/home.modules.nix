{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.agents.pi;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.agents.pi = {
    enable = mkEnableOption "Pi coding agent with pi-acp ACP adapter";
  };

  config = mkIf cfg.enable
    {
      home.packages = with pkgs; [
        pi-coding-agent
        (callPackage ./pi-acp-package.nix { })
      ];
    };
}
