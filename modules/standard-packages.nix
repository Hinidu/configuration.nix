{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    awscli
    beam.packages.erlangR21.elixir
    ctags
    curl
    dmenu
    dnsutils
    erlangR21
    f2fs-tools
    file
    fish
    git
    gnumake
    go_1_13
    (haskellPackages.ghcWithPackages (self: [
      self.ghc
      self.xmobar
      self.xmonad
      self.xmonad-contrib
    ]))
    neovim
    (python3.withPackages (self: [self.boto3]))
    ripgrep
    terraform_0_12
    unrar
    unzip
    vifm
    wget
    xlibs.xmessage
    xorg.luit
    zip
    zoom-us
  ];

  programs.fish.enable = true;
  programs.ssh.startAgent = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4ee2", MODE="0600", OWNER="hinidu"
  '';

  services.unclutter.enable = true;

  virtualisation.docker.enable = true;
}
