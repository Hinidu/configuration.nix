{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ctags
    exercism
    fish
    git
    haskellPackages.ghc
    haskellPackages.testFrameworkHunit
    haskellPackages.xmobar
    haskellPackages.xmonad
    haskellPackages.xmonadContrib
    haskellPackages.xmonadExtras
    nix-repl
    vifm
    vim
    wget
    xlibs.xmessage
  ];
}
