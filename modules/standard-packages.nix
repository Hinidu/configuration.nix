{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ctags
    exercism
    fish
    git
    (haskellPackages.ghcWithPackages (self: [
      self.ghc
      self.ghcMod
      self.HaTeX
      self.testFrameworkHunit
      self.xmobar
      self.xmonad
      self.xmonadContrib
      self.xmonadExtras
    ]))
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
