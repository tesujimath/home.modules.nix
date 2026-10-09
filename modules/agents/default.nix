{ flakePkgs }:
{ ... }:

{
  imports = [
    ./agent-shell-support.nix
    ./claude.nix
    (import ./crit.nix { inherit flakePkgs; })
    ./cursor.nix
    ./deprecated.nix
    ./goose.nix
    ./pi.nix
    ./skills.nix
    (import ./oh-my-pi.nix { inherit flakePkgs; })
  ];
}
