{ config, pkgs, lib, ... }:

let
  cfg = config.tesujimath.languages;
  inherit (lib) mkIf mkOption;
  inherit (pkgs) symlinkJoin;

  # nixpkgs' bicep-lsp is pinned to 0.34.44; this shadows it with a current build
  bicep-lsp = pkgs.callPackage ./bicep-lsp.nix { };

  prettier-with-plugins = pkgs.callPackage ./prettier-with-plugins.nix { };

  language-packages =
    with pkgs; {
      # languages whose support simply needs some packages are listed here;
      # more complex ones, such as clojure, are imported as modules

      bash = [ bash-language-server shfmt ];

      beancount = [ beancount-language-server ];

      bicep = [ bicep-lsp ];

      c = [ clang-tools ];

      csharp = [ csharpier roslyn-ls ];

      dockerfile = [ dockerfile-language-server ];

      fennel = [ fennel-ls fnlfmt ];

      fish = [ fish-lsp ];

      fsharp = [ fsautocomplete fantomas dotnet-sdk_10 ]; # SDK for interactive and REPL

      go = [ go gopls ];

      jinja = [ jinja-lsp prettier-with-plugins ];

      json = [ vscode-langservers-extracted ];

      jsonnet = [ jsonnet-language-server jsonnet ];

      markdown = [ marksman ];

      nix = [ nil nixpkgs-fmt ];

      rust = [ rust-analyzer rustfmt ];

      terraform = [ terraform-ls ];

      toml = [ taplo ];

      typst = [
        # typst-lsp is broken just now
        # typst-lsp
        typstyle
      ];

      yaml = [ yaml-language-server ];
    };

  # needed for multiple LSPs for eglot
  rassumfrassum_034 = pkgs.rassumfrassum.overrideAttrs (attrs: rec {
    version = "0.3.4";

    src = pkgs.fetchFromGitHub {
      owner = "joaotavora";
      repo = "rassumfrassum";
      tag = "v${version}";
      hash = "sha256-q8Pv+E+UejK3z5xCw44Gji2xJ01uIo18qS5LHpLc5HE=";
    };
  });

in
{
  imports = [
    ./clojure
    ./python
    ./typescript
  ];

  options.tesujimath = {
    languages =
      # an attrset with <language>.enable for each language
      (builtins.mapAttrs (name: _packages: { enable = lib.mkEnableOption name; }) language-packages) // {
        packages = mkOption {
          type = lib.types.listOf lib.types.package;
          description = "Programming language support packages for combining";
          internal = true;
          visible = false;
          default = [ ];
        };
      };
  };

  config.tesujimath.languages.packages = (lib.concatLists (lib.mapAttrsToList
    (name: packages: if cfg.${name}.enable then packages else [ ])
    language-packages))
  ++ (if config.tesujimath.emacs.enable then [
    # needed for multiple LSPs in eglot
    rassumfrassum_034
  ] else [ ]);

  config = {
    home = {
      packages =
        let
          language-support = symlinkJoin
            {
              name = "language-support";
              paths = config.tesujimath.languages.packages;
            };
        in
        [
          language-support
        ];
    };

    # ignored unless fish enabled
    programs.fish.interactiveShellInit =
      (if (cfg.csharp.enable || cfg.fsharp.enable) then ''

          # dotnet completions
          dotnet completions script fish | source
'' else "");
  };
}
