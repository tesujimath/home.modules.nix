# Backwards compatibility for the old tesujimath.agentic-engineering namespace,
# which was renamed to tesujimath.agents.  Using an old option still works, but
# warns.
{ lib, ... }:

let
  # Like lib.mkRenamedOptionModule, but without its `use = builtins.trace ...`,
  # which fires whenever the alias is *read*, even when nobody defines it.  The
  # `warnings` entry doRename adds is conditional on the old option actually
  # being defined, which is the warning we want.
  renamed = path: lib.doRename {
    from = [ "tesujimath" "agentic-engineering" ] ++ path;
    to = [ "tesujimath" "agents" ] ++ path;
    visible = false;
    warn = true;
    use = lib.id;
  };
in
{
  imports = map renamed [
    [ "agent-shell-support" "enable" ]
    [ "claude" "enable" ]
    [ "goose" "enable" ]
    [ "oh-my-pi" "enable" ]
    [ "skills" "enable" ]
  ];
}
