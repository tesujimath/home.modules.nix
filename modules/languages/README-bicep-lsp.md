# bicep-lsp override

`nixpkgs` pins `bicep-lsp` to 0.34.44 (released 2025-03-24), which ships Azure
resource-type schemas from that date. `bicep-lsp.nix` shadows it with a current
build so resource types added since then autocomplete and validate.

Note that `nixpkgs`' `bicep` (the CLI) is versioned independently — it was at
0.39.26 when this override was written, so the two are not in lockstep either
way. Drop this override once `nixpkgs` catches up.

## Bumping the version

1. Set `version` in `bicep-lsp.nix`, and blank `src.hash` to
   `lib.fakeHash`. Build, and copy the `got:` hash from the error.

2. Check whether the target framework moved:

       curl -sS https://raw.githubusercontent.com/Azure/bicep/v$VERSION/global.json
       curl -sS https://raw.githubusercontent.com/Azure/bicep/v$VERSION/src/Bicep.LangServer/Bicep.LangServer.csproj

   `global.json`'s `sdk.version` is the string `postPatch` rewrites, and the
   `.csproj` `TargetFramework` determines which `dotnetCorePackages.sdk_*_0`
   and `runtime_*_0` to use. Both changed between 0.34 (net8.0) and 0.46
   (net10.0).

3. Regenerate the NuGet lockfile. The package lives in a Home Manager module
   rather than a flake output, so drive it through the flake's own nixpkgs:

       nix build --impure --out-link /tmp/fetch-deps --expr '
         let f = builtins.getFlake "path:'"$PWD"'/../..";
             pkgs = f.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
         in (pkgs.callPackage ./bicep-lsp.nix {}).fetch-deps'
       /tmp/fetch-deps

   With no argument it rewrites `bicep-lsp-deps.json` in place. It needs
   network access and takes a few minutes.

4. Build to confirm, substituting the same expression without `.fetch-deps`.
