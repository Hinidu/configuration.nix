{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    amneziawg-go
    amneziawg-tools
    android-tools
    awscli2
    beam.packages.erlang_27.elixir_1_17
    binutils
    blender
    claude-agent-acp
    (claude-code.overrideAttrs (_: {
      version = "2.1.322";
      src = fetchurl {
        url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/2.1.322/linux-x64/claude";
        sha256 = "bfb3703ad5380242328459bc62ada4bde8ae7ba57c6e1eeadb9c00e08874c478";
      };
    }))
    clang
    clang-tools
    cmake
    csharp-ls
    curl
    dmenu
    dnsutils
    dotnetCorePackages.sdk_10_0
    elixir-ls
    elmPackages.elm
    erlang_27
    f2fs-tools
    ffmpeg
    file
    fish
    ghc
    git
    gnumake
    htop
    imagemagick
    inetutils
    jq
    lldb
    lshw
    lua5_1
    luit
    neovim
    nil
    nixpkgs-fmt
    nodejs
    openssl
    p7zip
    pamixer
    pandoc
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
    qrencode
    rclone
    redis
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
    wget
    xmessage
    xray
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
