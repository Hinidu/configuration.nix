{ config, pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # -env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    chromiumBeta
    ctags
    fish
    git
    haskellPackages.ghc
    haskellPackages.xmobar
    haskellPackages.xmonad
    haskellPackages.xmonadContrib
    haskellPackages.xmonadExtras
    mpv
    nix-repl
    rxvt_unicode
    transmission
    vifm
    vim
    wget
    xlibs.xmessage
  ];

  fonts.fonts = [ pkgs.terminus_font ];
}
