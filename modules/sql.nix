{ config, lib, pkgs, ... }:

let
  cfg = config.tesujimath.sql;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.sql = {
    enable = mkEnableOption "sql";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      sqlcmd
    ];

    # ignored unless fish enabled
    programs.fish.completions = {
      sqlcmd.body = builtins.readFile
        (pkgs.runCommand "sqlcmd-fish-completion" { } ''
          # naughty sqlcmd tries to write config to $HOME
          HOME=$TMPDIR ${pkgs.sqlcmd}/bin/sqlcmd completion fish > $out
        '') + ''

        # sqlcmd __complete can't list root subcommands
        complete -c sqlcmd -n __fish_use_subcommand -f -a completion -d 'Generate autocompletion script'
        complete -c sqlcmd -n __fish_use_subcommand -f -a config -d 'Modify sqlconfig files'
        complete -c sqlcmd -n __fish_use_subcommand -f -a create -d 'Install/Create SQL Server, Azure SQL, and Tools'
        complete -c sqlcmd -n __fish_use_subcommand -f -a delete -d 'Uninstall/Delete the current context'
        complete -c sqlcmd -n __fish_use_subcommand -f -a help -d 'Help about any command'
        complete -c sqlcmd -n __fish_use_subcommand -f -a open -d 'Open tools for current context'
        complete -c sqlcmd -n __fish_use_subcommand -f -a query -d 'Run a query against the current context'
        complete -c sqlcmd -n __fish_use_subcommand -f -a start -d 'Start current context'
        complete -c sqlcmd -n __fish_use_subcommand -f -a stop -d 'Stop current context'
      '';
    };
  };
}
