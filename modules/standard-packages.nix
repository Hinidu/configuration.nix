{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    android-tools
    awscli2
    beam.packages.erlang_27.elixir_1_17
    binutils
    claude-agent-acp
    claude-code
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
    luit
    neovim
    nil
    nixpkgs-fmt
    nodejs
    openssl
    p7zip
    pamixer
    pinentry-curses
    poppler-utils
    (python3.withPackages (
      ps: with ps; [
        boto3
        paramiko
        pandas
        matplotlib
        duckdb
        pyarrow
        pymupdf
        xlrd
      ]
    ))
    ripgrep
    roslyn-ls
    ruby
    ssm-session-manager-plugin
    terraform
    unrar
    unzip
    vifm
    wget
    xmessage
    zip
  ];

  programs.amnezia-vpn.enable = true;

  programs.fish.enable = true;
  programs.gnupg.agent = {
    enable = true;
  };
  programs.ssh.startAgent = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    icu
    openssl
    libcap
    attr
    util-linux
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4ee2", MODE="0600", OWNER="hinidu"
  '';

  services.unclutter.enable = true;

  virtualisation.docker.enable = true;
}
