{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    aspell
    aspellDicts.en
    aspellDicts.ru
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
