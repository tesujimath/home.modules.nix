# An org-protocol:// URL scheme handler for macOS, which simply forwards the
# URL to emacsclient.  See org-protocol.m for why this is needed.
{ lib, stdenv, writeText, emacs }:

let
  name = "org-protocol";

  infoPlist = writeText "Info.plist" (lib.generators.toPlist { escape = true; } {
    CFBundleDevelopmentRegion = "English";
    CFBundleExecutable = name;
    CFBundleIdentifier = "org.nixos.${name}";
    CFBundleInfoDictionaryVersion = "6.0";
    CFBundleName = name;
    CFBundlePackageType = "APPL";
    CFBundleShortVersionString = "1.0";
    CFBundleURLTypes = [
      {
        CFBundleURLName = "Org Protocol URL";
        CFBundleURLSchemes = [ "org-protocol" ];
      }
    ];
    # background-only app: no Dock icon, no menu bar
    LSUIElement = true;
  });
in
stdenv.mkDerivation {
  pname = name;
  version = "1.0";

  src = ./org-protocol.m;
  dontUnpack = true;

  buildPhase = ''
    runHook preBuild

    $CC -O2 -fobjc-arc -framework AppKit \
      -DEMACSCLIENT='"${emacs}/bin/emacsclient"' \
      -o ${name} $src

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    contents=$out/Applications/${name}.app/Contents
    mkdir -p $contents/MacOS
    install -m 555 ${name} $contents/MacOS/${name}
    install -m 444 ${infoPlist} $contents/Info.plist

    runHook postInstall
  '';

  meta = {
    description = "org-protocol:// URL scheme handler for macOS, forwarding to emacsclient";
    platforms = lib.platforms.darwin;
    mainProgram = name;
  };
}
