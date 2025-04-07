{ config, pkgs, lib, ... }:

{
  # Move somewhere
  services.libinput.enable = false;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    xkb = {
      layout = "us,ru";
      options = "grp:alt_shift_toggle,grp_led:scroll";
    };

    dpi = 200;
    upscaleDefaultCursor = true;

    synaptics = {
      enable = true;
      twoFingerScroll = true;
    };

    displayManager.sessionCommands = ''
      xrdb "${pkgs.writeText "xrdb.conf" ''
        URxvt.font: xft:Source Code Pro:size=10:autohint=true:antialias=true
        URxvt.perl-ext-common: default,matcher
        URxvt.scrollBar: off
        URxvt.scrollTtyOutput: false
        URxvt.scrollWithBuffer: true
        URxvt.scrollTtyKeypress: true
        URxvt.saveLines: 100000
        URxvt.termName: xterm-256color
        URxvt.url-launcher: chromium
        URxvt.matcher.button: 1
        URxvt.underlineURLs: true
        URxvt.urgentOnBell: true
        URxvt.cursorBlink: true

        #define S_base03        #002b36
        #define S_base02        #073642
        #define S_base01        #586e75
        #define S_base00        #657b83
        #define S_base0         #839496
        #define S_base1         #93a1a1
        #define S_base2         #eee8d5
        #define S_base3         #fdf6e3

        *background:            S_base3
        *foreground:            S_base00
        *fadeColor:             S_base3
        *cursorColor:           S_base01
        *pointerColorBackground:S_base1
        *pointerColorForeground:S_base01

        #define S_yellow        #b58900
        #define S_orange        #cb4b16
        #define S_red           #dc322f
        #define S_magenta       #d33682
        #define S_violet        #6c71c4
        #define S_blue          #268bd2
        #define S_cyan          #2aa198
        #define S_green         #859900

        !! black dark/light
        *color0:                S_base02
        *color8:                S_base03

        !! red dark/light
        *color1:                S_red
        *color9:                S_orange

        !! green dark/light
        *color2:                S_green
        *color10:               S_base01

        !! yellow dark/light
        *color3:                S_yellow
        *color11:               S_base00

        !! blue dark/light
        *color4:                S_blue
        *color12:               S_base0

        !! magenta dark/light
        *color5:                S_magenta
        *color13:               S_violet

        !! cyan dark/light
        *color6:                S_cyan
        *color14:               S_base1

        !! white dark/light
        *color7:                S_base2
        *color15:               S_base3
      ''}"
    '';

    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
    };
  };

  # Is needed for teamviewer for example.
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    google-chrome
    libreoffice
    mpv
    rxvt-unicode
    scrot
    slack
    steam
    steam-run
    tdesktop
    unityhub
    xclip
    xorg.xbacklight
    zathura
    zoom-us
  ];

  # Is needed for Unity3D
  security.chromiumSuidSandbox.enable = true;

  fonts.packages = with pkgs; [ corefonts nerdfonts source-code-pro ];
}
