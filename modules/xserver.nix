{ config, pkgs, lib, ... }:

{
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    layout = "us,ru";
    xkbOptions = "grp:alt_shift_toggle,grp_led:scroll";

    videoDrivers = [ "intel" "nouveau" ];

    synaptics = {
      enable = true;
      twoFingerScroll = true;
    };

    displayManager.slim = {
      # enable = true;
      theme = pkgs.stdenv.mkDerivation {
        name = "nixos-solarized-theme";
        src = pkgs.fetchurl {
          url = "https://github.com/Hinidu/nixos-solarized-slim-theme/archive/1.2.tar.gz";
          sha256 = "f8918f56e61d4b8f885a4dfbf1285aeac7d7e53a7458e32942a759fedfd95faf";
        };
        phases = [ "unpackPhase" "patchPhase" "installPhase" ];
        patchPhase = let
          headCount = lib.length config.services.xserver.xrandrHeads;
          headFactor = if headCount == 0 then 1 else headCount;
          centerLeft = 100 / (headFactor * 2);
        in ''
          sed -i \
            -e 's/^\(\(input_panel\|msg\|session\)_x\s\+\)[0-9]\+%/\1${toString centerLeft}%/' \
            slim.theme
        '';
        installPhase = ''cp -R . "$out"'';
      };
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


        ! Solarized color scheme for the X Window System
        !
        ! http://ethanschoonover.com/solarized


        ! Common

        #define S_yellow        #b58900
        #define S_orange        #cb4b16
        #define S_red           #dc322f
        #define S_magenta       #d33682
        #define S_violet        #6c71c4
        #define S_blue          #268bd2
        #define S_cyan          #2aa198
        #define S_green         #859900


        ! Dark

        #define S_base03        #002b36
        #define S_base02        #073642
        #define S_base01        #586e75
        #define S_base00        #657b83
        #define S_base0         #839496
        #define S_base1         #93a1a1
        #define S_base2         #eee8d5
        #define S_base3         #fdf6e3


        ! Light

        ! #define S_base03        #fdf6e3
        ! #define S_base02        #eee8d5
        ! #define S_base01        #93a1a1
        ! #define S_base00        #839496
        ! #define S_base0         #657b83
        ! #define S_base1         #586e75
        ! #define S_base2         #073642
        ! #define S_base3         #002b36


        ! To only apply colors to your terminal, for example, prefix
        ! the color assignment statement with its name. Example:
        !
        ! URxvt*background:            S_base03

        *background:              S_base03
        *foreground:              S_base0
        *fading:                  40
        *fadeColor:               S_base03
        *cursorColor:             S_base1
        *pointerColorBackground:  S_base01
        *pointerColorForeground:  S_base1

        *color0:                  S_base02
        *color1:                  S_red
        *color2:                  S_green
        *color3:                  S_yellow
        *color4:                  S_blue
        *color5:                  S_magenta
        *color6:                  S_cyan
        *color7:                  S_base2
        *color9:                  S_orange
        *color8:                  S_base03
        *color10:                 S_base01
        *color11:                 S_base00
        *color12:                 S_base0
        *color13:                 S_violet
        *color14:                 S_base1
        *color15:                 S_base3
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
    chromium
    libreoffice
    mpv
    rxvt_unicode
    scrot
    slack
    steam
    steam-run
    transmission
    unity3d
    xclip
    zathura
  ];

  # Is needed for Unity3D
  security.chromiumSuidSandbox.enable = true;

  fonts.fonts = [ pkgs.source-code-pro ];

  services.teamviewer.enable = true;
}
