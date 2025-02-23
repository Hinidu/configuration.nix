{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    awscli2
    beam.packages.erlang_24.elixir_1_12
    ctags
    curl
    dmenu
    dnsutils
    dotnetCorePackages.sdk_8_0
    erlang_24
    f2fs-tools
    file
    fish
    git
    gnumake
    (haskellPackages.ghcWithPackages (self: [
      self.ghc
      self.xmobar
      self.xmonad
      self.xmonad-contrib
    ]))
    neovim
    openssl
    pinentry
    (python3.withPackages (self: [self.boto3 self.paramiko]))
    ripgrep
    terraform
    unrar
    unzip
    vifm
    wget
    xorg.xmessage
    xorg.luit
    zip
  ];

  programs.fish.enable = true;
  programs.gnupg.agent = {
    enable = true;
  };
  programs.ssh.startAgent = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4ee2", MODE="0600", OWNER="hinidu"
  '';

  services.unclutter.enable = true;

  virtualisation.docker.enable = true;
}
