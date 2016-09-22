{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    aspell
    aspellDicts.en
    aspellDicts.ru
    cmake
    ctags
    curl
    dmenu2
    file
    fish
    gcc
    gimp
    git
    gnumake
    (haskellPackages.ghcWithPackages (self: [
      self.ghc
      self.xmobar
      self.xmonad
      self.xmonad-contrib
    ]))
    nix-repl
    p7zip
    python
    telnet
    testdisk
    unrar
    unzip
    vagrant
    vifm
    vimHugeX
    wget
    xlibs.xmessage
    xorg.luit
    zip
  ];

  services.teamviewer.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4ee2", MODE="0600", OWNER="hinidu"
  '';
}
