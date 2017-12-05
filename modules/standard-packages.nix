{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    aspell
    aspellDicts.en
    aspellDicts.ru
    awscli
    beam.packages.erlangR20.elixir
    cmake
    ctags
    curl
    dmenu2
    dnsutils
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
      self.xmobar
      self.xmonad
      self.xmonad-contrib
    ]))
    hugo
    neovim
    python3
    ripgrep
    terraform_0_10
    testdisk
    unrar
    unzip
    vifm
    wget
    xlibs.xmessage
    xorg.luit
    zip
  ];

  programs.fish.enable = true;
  programs.ssh.startAgent = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4ee2", MODE="0600", OWNER="hinidu"
  '';

  virtualisation.docker.enable = true;
}
