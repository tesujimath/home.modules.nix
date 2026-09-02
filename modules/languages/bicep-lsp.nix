# Overrides nixpkgs' bicep-lsp, which is pinned to 0.34.44 (released 2025-03-24)
# and so ships badly stale Azure resource-type schemas.
#
# Upstream bicep moved to net10.0 after 0.34, hence the dotnet 10 SDK/runtime
# here rather than the dotnet 8 nixpkgs uses.
#
# To regenerate deps.json after bumping version, see the sibling README-bicep-lsp.md
{
  autoPatchelfHook,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  icu,
  lib,
  libkrb5,
  openssl,
  stdenv,
}:

buildDotnetModule rec {
  pname = "bicep-lsp";
  version = "0.46.1";

  src = fetchFromGitHub {
    owner = "Azure";
    repo = "bicep";
    tag = "v${version}";
    hash = "sha256-I3u+MUGwODzC9fIOww9eh3E+4+ZiRTWVeG5IDEbyZLM=";
  };

  projectFile = "src/Bicep.LangServer/Bicep.LangServer.csproj";

  # https://github.com/Azure/bicep/blob/v0.46.1/global.json pins 10.0.302,
  # which is ahead of nixpkgs' SDK, so relax it to whatever we have.
  postPatch = ''
    substituteInPlace global.json --replace-warn "10.0.302" "${dotnetCorePackages.sdk_10_0.version}"
  '';

  nugetDeps = ./bicep-lsp-deps.json;

  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  dotnet-runtime = dotnetCorePackages.runtime_10_0;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    icu
    libkrb5
    openssl
    stdenv.cc.cc.lib
  ];

  doCheck = !(stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64); # mono is not available on aarch64-darwin

  meta = {
    description = "Language server for Bicep, Azure's DSL for declarative resource deployment";
    homepage = "https://github.com/Azure/bicep/";
    changelog = "https://github.com/Azure/bicep/releases/tag/v${version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    badPlatforms = [ "aarch64-linux" ];
    mainProgram = "Bicep.LangServer";
  };
}
