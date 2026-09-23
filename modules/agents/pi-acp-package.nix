{ lib
, buildNpmPackage
, fetchFromGitHub
, makeWrapper
, pi-coding-agent
}:

# `pi-acp` is an ACP (Agent Client Protocol) adapter for the pi coding agent.
# An ACP client such as Zed spawns `pi-acp` over stdio, and `pi-acp` in turn
# spawns `pi --mode rpc` and bridges the two.  It is not a pi plugin, it is a
# standalone CLI, so it is packaged as an ordinary npm package.
#
# Upstream: https://github.com/svkozak/pi-acp
# npm package: https://www.npmjs.com/package/pi-acp

buildNpmPackage (finalAttrs: {
  pname = "pi-acp";
  version = "0.0.33";

  src = fetchFromGitHub {
    owner = "svkozak";
    repo = "pi-acp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-fENOOdooi4XbIDjcr02q8qzUCzdo2IW/Bca43SawZ44=";
  };

  npmDepsHash = "sha256-/fX79XucKojL/6gZbK5eizEfrXso8rlTgiHfJffmDuY=";

  nativeBuildInputs = [ makeWrapper ];

  # pi-acp spawns `pi` from PATH.  ACP clients are usually GUI applications
  # which don't inherit the login shell's PATH, so bake it in rather than
  # relying on the ambient environment.
  postFixup = ''
    wrapProgram $out/bin/pi-acp \
      --prefix PATH : ${lib.makeBinPath [ pi-coding-agent ]}
  '';

  meta = {
    description = "ACP adapter for the pi coding agent";
    homepage = "https://github.com/svkozak/pi-acp";
    license = lib.licenses.mit;
    mainProgram = "pi-acp";
  };
})
