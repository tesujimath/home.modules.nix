{ config, pkgs, lib, ... }:

let
  cfg = config.tesujimath.mitmproxy;
  inherit (lib) mkEnableOption mkIf;

  mitm-view = with pkgs; writeShellApplication {
    name = "mitm-view";
    runtimeInputs = [ jnv jq less ];
    text = builtins.readFile ./mitm-view;
  };
in
{
  options.tesujimath.mitmproxy = {
    enable = mkEnableOption "mitmproxy";
  };

  config = mkIf cfg.enable {
    home = {
      file = {
        ".mitmproxy/config.yaml".source = ./config.yaml;
      };

      packages =
        with pkgs;
        [
          python3Packages.mitmproxy
          mitm-view
        ];
    };

    # ignored unless fish is enabled
    programs.fish = {
      functions = {
        mitmproxy = {
          body = ''
            PAGER=mitm-view command mitmproxy $argv
          '';
          wraps = "mitmproxy";
        };

        with-mitmproxy.body = ''
          HTTPS_PROXY=https://localhost:8080 HTTPS_PROXY=https://localhost:8080 NODE_EXTRA_CA_CERTS=$HOME/.mitmproxy/mitmproxy-ca-cert.pem $argv
        '';
      };
      completions = {
        with-mitmproxy.body = ''
          complete -c with-mitmproxy -xa '(__fish_complete_subcommand)'
        '';
      };
    };
  };
}
