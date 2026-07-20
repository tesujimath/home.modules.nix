{
  description = "Simon Guest's Nix Home Manager modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bash-env-json = {
      url = "github:tesujimath/bash-env-json/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    {
      homeManagerModules.default =
        let
          flakePkgsForSystem = system: {
            bash-env-json = inputs.bash-env-json.packages.${system}.default;
          };
        in
        {
          imports = [
            (import ./main.nix { inherit flakePkgsForSystem; })
          ];
        };

      # for nix repl
      inherit inputs;
    };
}
