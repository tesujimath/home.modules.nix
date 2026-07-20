{
  description = "Simon Guest's Nix Home Manager modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default";

    bash-env-json = {
      url = "github:tesujimath/bash-env-json/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    let
      inherit (inputs) bash-env-json nixpkgs home-manager systems;

      eachSystem = nixpkgs.lib.genAttrs (import systems);

      flakePkgsFor = system: {
        bash-env-json = bash-env-json.packages.${system}.default;
      };

      docsFor = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          hmEval = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              (import ./main.nix { inherit flakePkgsFor; })
              {
                # dummy values so Home Manager's own modules evaluate; docs-build only
                home.username = "docs";
                home.homeDirectory = "/home/docs";
                home.stateVersion = "24.05";
              }
            ];
          };
        in
        pkgs.nixosOptionsDoc {
          options = {
            inherit (hmEval.options) tesujimath;
          };
        };

    in
    {
      homeManagerModules.default =
        {
          imports = [
            (import ./main.nix { inherit flakePkgsFor; })
          ];
        };

      packages = eachSystem (system: { docs = (docsFor system).optionsCommonMark; });

      apps = eachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          optionsMd = (docsFor system).optionsCommonMark;

          buildDocs = pkgs.writeShellApplication {
            name = "build-docs";
            runtimeInputs = [ pkgs.mdbook ];
            text = ''
              set -euo pipefail
              workdir=$(mktemp -d)
              #trap 'rm -rf "$workdir"' EXIT
              rsync -a --exclude /book ./doc/ "$workdir/"
              cp ${optionsMd} "$workdir/src/options.md"
              mdbook build "$workdir" -d "./doc/book"
              echo "Docs built at ./doc/book"
            '';
          };
        in
        {
          buildDocs = {
            type = "app";
            program = "${buildDocs}/bin/build-docs";
          };
        }
      );

      # for nix repl
      inherit inputs;
    };
}
