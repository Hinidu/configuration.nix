{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    aspell
    aspellDicts.en
    aspellDicts.ru
    cmake
    ctags
    erlang
    exercism
    file
    fish
    gcc
    gimp
    git
    gnumake
    (haskellPackages.ghcWithPackages (self: [
      self.cabal2nix
      self.ghc
      self.ghcMod
      self.permutation
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
    unzip
    vifm
    vimHugeX
    wget
    xlibs.xmessage
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql94;
  };
}
