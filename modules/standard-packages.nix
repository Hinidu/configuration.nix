{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    awscli2
    beam.packages.erlang_27.elixir_1_17
    binutils
    csharp-ls
    ctags
    curl
    dmenu
    dnsutils
    dotnetCorePackages.sdk_10_0
    elixir-ls
    elmPackages.elm
    erlang_27
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
    htop
    imagemagick
    inetutils
    jq
    lshw
    neovim
    openssl
    p7zip
    pamixer
    pinentry-curses
    (python3.withPackages (self: [self.boto3 self.paramiko]))
    ripgrep
    ruby
    terraform
    unrar
    unzip
    vifm
    wget
    xorg.xmessage
    xorg.luit
    zip
  ];

  programs.amnezia-vpn.enable = true;

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
