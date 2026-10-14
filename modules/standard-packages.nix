{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    android-tools
    awscli2
    beam.packages.erlang_27.elixir_1_17
    binutils
    claude-agent-acp
    (claude-code.overrideAttrs (_: {
      version = "2.1.299";
      src = fetchurl {
        url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/2.1.299/linux-x64/claude";
        sha256 = "2d894a4b1bfaaa9aab72aeff7803e3c73bc2510f279a171f6b8f59f72d17d077";
      };
    }))
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
    (callPackage ../packages/perfetto.nix { })
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
    rclone
    ripgrep
    roslyn-ls
    ruby
    ssm-session-manager-plugin
    terraform
    typescript
    unrar
    unzip
    usbutils
    uv
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
