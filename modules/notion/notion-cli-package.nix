{ lib
, stdenvNoCC
, fetchurl
}:

# Notion CLI (`ntn`) is published to npm as a single tarball that bundles
# prebuilt, statically-linked binaries for every supported platform
# (darwin-arm64, darwin-x64, linux-arm64, linux-x64, win32-x64). npm's
# preinstall script just copies the right one into place, so we can skip
# npm entirely and do the same thing here.
#
# Upstream: https://developers.notion.com/cli
# npm package: https://www.npmjs.com/package/ntn

let
  version = "0.15.0";

  # Single tarball contains every platform's binary, so one hash covers
  # all systems. Update both when bumping `version`:
  #   nix store prefetch-file --json https://registry.npmjs.org/ntn/-/ntn-${version}.tgz
  src = fetchurl {
    url = "https://registry.npmjs.org/ntn/-/ntn-${version}.tgz";
    hash = "sha256-TivIugK8BrFLb9E20FiIvztArRusSFX3/B0Bjm0pb7I=";
  };

  # Map Nix's system strings to the directory names inside the npm tarball.
  platformDir = {
    aarch64-darwin = "ntn-darwin-arm64";
    x86_64-darwin = "ntn-darwin-x64";
    aarch64-linux = "ntn-linux-arm64";
    x86_64-linux = "ntn-linux-x64";
  };
in
stdenvNoCC.mkDerivation {
  pname = "ntn";
  inherit version src;

  # It's a plain tarball (npm pack format), not a "real" source archive.
  sourceRoot = "package";

  dontConfigure = true;
  dontBuild = true;

  installPhase =
    let
      system = stdenvNoCC.hostPlatform.system;
      dir = platformDir.${system}
        or (throw "ntn: unsupported system ${system}");
      exeName = if stdenvNoCC.hostPlatform.isWindows then "ntn.exe" else "ntn";
    in
    ''
      runHook preInstall
      install -Dm755 "dist/${dir}/${exeName}" "$out/bin/${exeName}"
      runHook postInstall
    '';

  # The upstream binaries are ad-hoc/Developer-ID signed by Notion; Nix's
  # fixup phase can invalidate that signature on macOS. Re-sign ad-hoc so
  # Gatekeeper doesn't refuse to run it.
  postFixup = lib.optionalString stdenvNoCC.hostPlatform.isDarwin ''
    if command -v codesign >/dev/null; then
      codesign -f -s - "$out/bin/ntn"
    fi
  '';

  meta = with lib; {
    description = "Command-line interface for Notion";
    homepage = "https://developers.notion.com/cli";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames platformDir;
    mainProgram = "ntn";
  };
}
