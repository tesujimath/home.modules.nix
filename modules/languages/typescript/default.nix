{ config, pkgs, lib, ... }:

let
  cfg = config.tesujimath.languages.typescript;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.languages.typescript.enable = mkEnableOption "typescript";

  config = mkIf cfg.enable
    {
      tesujimath.languages.packages =
        with pkgs;
        [
          biome
          deno
          typescript-language-server
        ];

      home.file = {
        ".config/rassumfrassum/deno-biome.py".text = ''
          def servers():
              """TypeScript preset using deno and biome."""
              return [
                  ['deno', 'lsp'],
                  ['biome', 'lsp-proxy'],
              ]
        '';
      };
    };
}
