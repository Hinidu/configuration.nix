{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    aspell
    aspellDicts.en
    aspellDicts.ru
    beam.packages.erlangR20.elixir
    cmake
    ctags
    curl
    dmenu2
    elmPackages.elm
    erlangR20
    file
    fish
    gcc
    gimp
    git
    gnumake
    go
    (haskellPackages.ghcWithPackages (self: [
      self.ghc
      self.QuickCheck
      self.xmobar
      self.xmonad
      self.xmonad-contrib
    ]))
    hugo
    neovim
    nix-repl
    p7zip
    platinum-searcher
    python
    telnet
    testdisk
    unrar
    unzip
    vagrant
    vifm
    vimHugeX
    vscode
    wget
    xlibs.xmessage
    xorg.luit
    zip
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4ee2", MODE="0600", OWNER="hinidu"
  '';
}
