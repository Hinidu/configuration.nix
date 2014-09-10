{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ctags
    exercism
    fish
    git
    haskellPackages.ghc
    haskellPackages.HaTeX
    haskellPackages.testFrameworkHunit
    haskellPackages.xmobar
    haskellPackages.xmonad
    haskellPackages.xmonadContrib
    haskellPackages.xmonadExtras
    nix-repl
    (texLiveAggregationFun {
      paths = [ texLive texLiveBeamer texLiveExtra texLiveModerncv ];
    })
    vifm
    vim
    wget
    xlibs.xmessage
  ];
}
