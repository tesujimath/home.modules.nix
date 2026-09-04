{ config, pkgs, lib, ... }:

let
  cfg = config.tesujimath.languages.python;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.languages.python.enable = mkEnableOption "python";

  config = mkIf cfg.enable
    {
      tesujimath.languages.packages =
        with pkgs;
        [
          pyright
          ruff
        ];

      home.file = {
        ".config/rassumfrassum/pyright-ruff.py".text = ''
          def servers():
              """Python preset using pyright and ruff."""
              return [
                  ['pyright-langserver', '--stdio'],
                  ['ruff', 'server'],
              ]
        '';
      };
    };
}
