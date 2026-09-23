{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.emacs;
  inherit (lib) mkEnableOption mkIf mkMerge;
  inherit (pkgs) stdenv;

  lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister";

  emacsWithPackages = (pkgs.emacsPackagesFor pkgs.emacs).withPackages (epkgs: with epkgs; [
    jinx # spellcheck support
    pdf-tools # for PDF preview in dirvish
    vterm # terminal emulator
  ]);

  # the macOS equivalent of the org-protocol.desktop entry below
  orgProtocolApp = pkgs.callPackage ./org-protocol-app.nix { emacs = emacsWithPackages; };
in
{
  options.tesujimath.emacs = {
    enable = mkEnableOption "emacs";
  };

  config = mkMerge [
    (mkIf cfg.enable
      {
        # all platforms
        programs = {
          emacs = {
            enable = true;
            package = emacsWithPackages;
          };
        };

        home.packages = with pkgs; [
          enchant # modern spell check abstraction layer, on macOS uses system dictionary

          # previewers for dirvish:
          _7zz # various archive formats
          epub-thumbnailer # e-books
          ffmpegthumbnailer # video
          mediainfo # audio/video metadata
          poppler-utils # pdftoppm for PDF preview
          vips # images
        ];
      })
    (mkIf (cfg.enable && stdenv.hostPlatform.isDarwin)
      {
        # macOS has no XDG, and GNU Emacs registers no URL schemes of its own,
        # so org-protocol:// needs a handler app of our own.  Scrim
        # (https://github.com/kickingvegas/scrim) does this job but is Mac App
        # Store only, so we build our own minimal equivalent instead.
        home.packages = [ orgProtocolApp ];

        # LaunchServices only scans a handful of well known directories, and
        # `targets.darwin.linkApps` puts a symlink rather than a bundle in
        # ~/Applications, so register the bundle in the store explicitly.
        home.activation.registerOrgProtocolHandler = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${lsregister} -f ${orgProtocolApp}/Applications/org-protocol.app
        '';
      })
    (mkIf (cfg.enable && !stdenv.hostPlatform.isDarwin)
      {
        # no XDG on macOS
        xdg.desktopEntries = {
          org-protocol = {
            # https://orgmode.org/worg/org-contrib/org-protocol.html
            # https://github.com/nix-community/home-manager/blob/master/modules/misc/xdg-desktop-entries.nix
            name = "org-protocol";
            comment = "Intercept calls from emacsclient to trigger custom actions";
            icon = "emacs";
            type = "Application";
            exec = "emacsclient -- %u";
            mimeType = [ "x-scheme-handler/org-protocol" ];
          };
        };

        # need to override the existing emacs.desktop registration for org-protocol
        # because that omits to pass the URL
        xdg.mimeApps = {
          defaultApplications = {
            "x-scheme-handler/org-protocol" = [ "org-protocol.desktop" ];
          };
        };
      })
  ];
}
