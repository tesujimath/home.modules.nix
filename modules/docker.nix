{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.docker;
  inherit (lib) mkEnableOption mkIf mkOption types;
  yamlFormat = pkgs.formats.yaml { };

  # Colima only mounts $HOME into the VM, so the certificates are inlined
  # rather than referenced by path.  They are split one per file, without
  # surrounding text, as update-ca-certificates expects.
  installCaCertificates =
    let
      certificates = lib.concatMapStrings (file: builtins.readFile file + "\n") cfg.caCertificateFiles;
    in
    ''
      set -eu
      staging=$(mktemp -d)
      awk -v dir="$staging" '
        /-----BEGIN CERTIFICATE-----/ { n++; f = sprintf("%s/%d.crt", dir, n) }
        f { print > f }
        /-----END CERTIFICATE-----/ { close(f); f = "" }
      ' <<'END_OF_CERTIFICATES'
      ${certificates}
      END_OF_CERTIFICATES
      target=/usr/local/share/ca-certificates/${cfg.caCertificatesName}
      # provision scripts run on every start, so only restart dockerd on change
      if ! diff -r "$staging" "$target" >/dev/null 2>&1; then
        rm -rf "$target"
        mv "$staging" "$target"
        chmod 755 "$target"
        update-ca-certificates
        systemctl restart docker
      else
        rm -rf "$staging"
      fi
    '';

  colimaSettings = lib.recursiveUpdate
    {
      inherit (cfg) cpu memory disk rosetta;
      # colima ignores the whole file if runtime is unset
      runtime = "docker";
      arch = "host";
      vmType = "vz";
      mountType = "virtiofs";
      mountInotify = true;
      binfmt = true;
      network.dnsHosts."host.docker.internal" = "host.lima.internal";
      provision = lib.optional (cfg.caCertificateFiles != [ ]) {
        mode = "system";
        script = installCaCertificates;
      };
    }
    cfg.extraSettings;
in
{
  options.tesujimath.docker = {
    enable = mkEnableOption "Docker CLI with Compose and Buildx, backed by a Colima VM (macOS only)";

    cpu = mkOption { default = 4; type = types.int; description = "Number of CPUs for the Colima VM"; };
    memory = mkOption { default = 8; type = types.int; description = "Memory in GiB for the Colima VM"; };
    disk = mkOption { default = 100; type = types.int; description = "Disk size in GiB for the Colima VM"; };

    rosetta = mkOption {
      default = pkgs.stdenv.hostPlatform.isAarch64;
      defaultText = lib.literalExpression "pkgs.stdenv.hostPlatform.isAarch64";
      type = types.bool;
      description = "Run linux/amd64 images using Rosetta";
    };

    setDockerHost = mkOption {
      default = true;
      type = types.bool;
      description = "Set DOCKER_HOST, for tools such as Testcontainers which ignore Docker contexts";
    };

    credsStore = mkOption {
      default = "osxkeychain";
      type = types.nullOr types.str;
      description = "Docker credential helper, or null to store registry credentials in config.json";
    };

    caCertificateFiles = mkOption {
      default = [ ];
      type = types.listOf types.path;
      description = "PEM files of extra CA certificates to trust in the Colima VM, e.g. for corporate TLS interception";
    };

    caCertificatesName = mkOption {
      default = "home-manager";
      type = types.strMatching "[A-Za-z0-9._-]+";
      description = "Name of the directory under /usr/local/share/ca-certificates in the Colima VM for caCertificateFiles";
    };

    extraSettings = mkOption {
      default = { };
      type = yamlFormat.type;
      description = "Extra Colima settings, merged over those derived from other options, see `colima template`";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "tesujimath.docker is only supported on macOS";
      }
    ];

    home.packages = with pkgs; [
      docker
      docker-compose # for scripts which still use the standalone command
      docker-credential-helpers
    ];

    services.colima = {
      enable = true;
      profiles.default = {
        isService = true;
        # colima would otherwise try to rewrite config.json, which is read-only
        isActive = false;
        inherit (cfg) setDockerHost;
        settings = colimaSettings;
      };
    };

    # colima detects Rosetta with pgrep, which is only in /usr/bin
    launchd.agents.colima-default.config.EnvironmentVariables.PATH =
      let colima = config.services.colima;
      in lib.mkForce (lib.makeBinPath [
        colima.package
        colima.perlPackage
        colima.dockerPackage
        colima.sshPackage
        colima.coreutilsPackage
        colima.curlPackage
        colima.bashPackage
        colima.kubectlPackage
        pkgs.darwin.DarwinTools
      ] + ":/usr/bin:/bin:/usr/sbin:/sbin");

    # colima delete removes the profile directory and with it the config file
    # above, so also provide it as the template for recreating the VM
    home.file."${config.services.colima.colimaHomeDir}/_templates/default.yaml".source =
      yamlFormat.generate "colima.yaml" colimaSettings;

    programs.docker-cli = {
      enable = true;
      settings = {
        # compose is already on the nixpkgs docker client's plugin path, but buildx is not
        cliPluginsExtraDirs = [ "${pkgs.docker-buildx}/libexec/docker/cli-plugins" ];
      } // lib.optionalAttrs (cfg.credsStore != null) {
        inherit (cfg) credsStore;
      };
    };
  };
}
