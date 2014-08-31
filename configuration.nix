# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "hinidu_notebook"; # Define your hostname.
  networking.wireless.enable = true;  # Enables wireless.

  # Select internationalisation properties.
  i18n = {
    consoleFont = "ter-v16v";
    consoleKeyMap = "ru";
    defaultLocale = "ru_RU.UTF-8";
  };

  nix.gc.automatic = true;

  time.timeZone = "Europe/Kaliningrad";

  # List packages installed in system profile. To search by name, run:
  # -env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    chromiumBeta
    ctags
    fish
    git
    haskellPackages.ghc
    haskellPackages.xmobar
    haskellPackages.xmonad
    haskellPackages.xmonadContrib
    haskellPackages.xmonadExtras
    mpv
    nix-repl
    rxvt_unicode
    transmission
    vifm
    vim
    wget
    xlibs.xmessage
  ];

  fonts.fonts = [ pkgs.terminus_font ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    layout = "us,ru";
    xkbOptions = "grp:alt_shift_toggle,grp_led:scroll";

    videoDrivers = [ "nouveau" ];

    synaptics = {
      enable = true;
      twoFingerScroll = true;
    };

    displayManager.slim.enable = true;

    # displayManager.lightdm.enable = true;

    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };

    windowManager.default = "xmonad";

    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
    };
  };

  services.transmission.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.kdm.enable = true;
  # services.xserver.desktopManager.kde4.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.hinidu = {
    group = "hinidu";
    extraGroups = [ "users" "wheel" ];
    uid = 1000;
    createHome = true;
    home = "/home/hinidu";
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEZqpiPcjrnjF39G042xjZTZ+sNExSlliqE3hmQQ8RqkXSp2Gjm62LVq1JQ6ttWEWCymD3HHFBAL7Cx0u+xttxhjn3P0wP9zHmiBmZrfZ4Da1EsZD+b24K9YJ4iLHYWM4+2MJ9UBWow6ZFJ5/S5FRKqY/MC9KjUwLvfHArOpt0ONt2gz2r+Gk0z0SYhxcFmYKGzh1GxVNxAGhbWo9YN6LGeJkjskc+3Znl3Hl1tpKVrMMZ1bU0/+hiSR4IwOXKL/3fo8A50tqgoTY0E5G9NrhjP8Tz0olXinrXSZszMZ6yysZA0510mxQXnWgF4HT3HFss4LbjOgRVyWgnZ7VcS4wX hinidu@hinidu_notebook" ];
  };

  users.extraUsers.olga = {
    group = "olga";
    extraGroups = [ "users" ];
    uid = 1001;
    createHome = true;
    home = "/home/olga";
    useDefaultShell = true;
  };

  users.extraGroups.hinidu.gid = 1000;
  users.extraGroups.olga.gid = 1001;

}
