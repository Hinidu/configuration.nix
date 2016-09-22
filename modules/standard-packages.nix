{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # androidenv.androidsdk_5_0_1
    aspell
    aspellDicts.en
    aspellDicts.ru
    cmake
    ctags
    curl
    dmenu2
    # erlang
    # exercism
    file
    fish
    # fsharp
    gcc
    gimp
    git
    gnumake
    (haskellPackages.ghcWithPackages (self: [
      # self.cabal2nix
      # self.clay
      self.ghc
      # self.ghcMod
      self.hakyll
      # self.permutation
      # self.testFrameworkHunit
      self.xmobar
      self.xmonad
    ]))
    # idea.android-studio
    # kibana
    # logstash
    mercurial
    mono
    # neovim
    nix-repl
    # openjdk
    p7zip
    python
    # sbt
    # scala
    # steam
    telnet
    testdisk
    # tintin
    # texLiveFull
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

  # services.elasticsearch.enable = true;

  # services.neo4j.enable = true;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql94;
  };

  services.teamviewer.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4ee2", MODE="0600", OWNER="hinidu"
  '';
}
