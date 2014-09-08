{ config, pkgs, ... }:

{
  nixpkgs.config = {
    allowUnfree = true;

    chromium = {
      enableGoogleTalkPlugin = true;
      enablePepperFlash = true;
      enablePepperPdf = true;
    };
  };

  # List packages installed in system profile. To search by name, run:
  # -env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    chromiumBeta
    ctags
    evince
    fish
    git
    haskellPackages.ghc
    haskellPackages.xmobar
    haskellPackages.xmonad
    haskellPackages.xmonadContrib
    haskellPackages.xmonadExtras
    libreoffice
    mpv
    nix-repl
    rxvt_unicode
    transmission
    vifm
    vim
    wget
    xarchiver
    xlibs.xmessage
    zathura
  ];

  fonts.fonts = [ pkgs.terminus_font ];
}
