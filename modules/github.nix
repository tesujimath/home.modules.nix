{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.github;
  inherit (lib) mkEnableOption mkIf;

  gh-notifications-clear-merged = pkgs.writeShellApplication {
    name = "gh-notifications-clear-merged";
    runtimeInputs = [ pkgs.gh ];
    text = ''
      usage() {
        cat <<EOF
      Usage: gh-notifications-clear-merged [-n|--dry-run] [--closed]

      Mark GitHub notifications for merged pull requests as done.

        -n, --dry-run  list what would be cleared without changing anything
        --closed       also clear pull requests closed without merging
      EOF
      }

      dry_run=false
      closed=false
      while [ $# -gt 0 ]; do
        case "$1" in
          -n | --dry-run) dry_run=true ;;
          --closed) closed=true ;;
          -h | --help) usage; exit 0 ;;
          *) usage >&2; exit 2 ;;
        esac
        shift
      done

      cleared=0
      kept=0
      while IFS=$'\t' read -r id url repo title; do
        state=$(gh api "$url" -q 'if .merged then "merged" else .state end')
        number=''${url##*/}
        if [ "$state" = merged ] || { $closed && [ "$state" = closed ]; }; then
          if ! $dry_run; then
            gh api -X DELETE "notifications/threads/$id" --silent
          fi
          printf 'clear\t%s\t%s#%s\t%s\n' "$state" "$repo" "$number" "$title"
          cleared=$((cleared + 1))
        else
          printf 'keep\t%s\t%s#%s\t%s\n' "$state" "$repo" "$number" "$title"
          kept=$((kept + 1))
        fi
      # read notifications stay in the inbox until done, but the API omits them without all=true
      done < <(gh api --paginate "notifications?all=true" \
        -q '.[] | select(.subject.type == "PullRequest") | [.id, .subject.url, .repository.full_name, .subject.title] | @tsv')

      if $dry_run; then
        echo "dry run: would clear $cleared, keep $kept"
      else
        echo "cleared $cleared, kept $kept"
      fi
    '';
  };
in
{
  options.tesujimath.github = {
    enable = mkEnableOption "GitHub utilities";
  };

  config = mkIf cfg.enable {
    home.packages = [
      gh-notifications-clear-merged
    ];
  };
}
