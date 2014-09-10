{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cmake
    ctags
    exercism
    fish
    gcc
    git
    gnumake
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
    python
    (texLiveAggregationFun {
      paths = [ texLive texLiveBeamer texLiveExtra texLiveModerncv ];
    })
    vifm
    vimHugeX
    wget
    xlibs.xmessage
  ];
}
