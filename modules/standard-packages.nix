{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cmake
    ctags
    exercism
    fish
    gcc
    gimp
    git
    gnumake
    (haskellPackages.ghcWithPackages (self: [
      self.ghc
      self.ghcMod
      self.testFrameworkHunit
      self.xmobar
      self.xmonad
      self.xmonadContrib
      self.xmonadExtras
    ]))
    ledger
    nix-repl
    python
    texLiveFull
    vifm
    vimHugeX
    wget
    xlibs.xmessage
  ];
}
