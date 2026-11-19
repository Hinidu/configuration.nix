{ config, pkgs, lib, ... }:

let
  colors = config.solarized.colors;
  dpi = config.display.dpi;
  # Whole-number GDK scale for apps that ignore Xft.dpi: 2 at 200 dpi
  gdkScale = builtins.floor (dpi / 96.0 + 0.5);
  bars = config.display.bars;

  # desktop.projects (modules/projects.nix) as a Haskell list for xmonad.hs; a
  # JSON string is a valid Haskell string literal for these plain names and paths
  haskellProjects = "[ " + lib.concatMapStringsSep "\n    , "
    (workspace: "Project { projectName = ${builtins.toJSON workspace.name}"
      + ", projectDirectory = ${builtins.toJSON workspace.directory}"
      + ", projectStartHook = Nothing }")
    config.desktop.projects + "\n    ]";

  # xmonad starts at login before the user's systemd has even created the
  # PipeWire socket, and xmobar's volume widget gives up on the "default"
  # mixer for good if it can't open it on start (shows N/A until restart).
  # So the main bar waits for the default audio output, but not forever: a
  # bar without volume is better than no bar.
  xmobarAfterAudio = pkgs.writeShellScript "xmobar-after-audio" ''
    for attempt in $(seq 50); do
      ${config.services.pipewire.wireplumber.package}/bin/wpctl inspect @DEFAULT_AUDIO_SINK@ >/dev/null 2>&1 && break
      sleep 0.2
    done
    exec xmobar "$@"
  '';
in
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

    inherit dpi;
    # The default X cursor is tiny on a HiDPI screen
    upscaleDefaultCursor = dpi >= 144;

    synaptics = {
      enable = true;
      twoFingerScroll = true;
    };

    # NixOS starts graphical-session.target (through its fake target for
    # sessions like xmonad) after these commands, but nothing stops it when
    # X exits. After logging out and in without a reboot it's still active, so
    # that start does nothing: the session's services (xss-lock, wallpaper)
    # stay with the dead X, and xss-lock, failing to connect to it, gives up
    # for good. Stopping the stale target first makes the start bring them up
    # again with the new DISPLAY
    displayManager.sessionCommands = ''
      ${config.systemd.package}/bin/systemctl --user stop graphical-session.target

      xrdb "${pkgs.writeText "xrdb.conf" ''
        Xft.dpi: ${toString dpi}

        #define S_base03        #002b36
        #define S_base02        #073642
        #define S_base01        #586e75
        #define S_base00        #657b83
        #define S_base0         #839496
        #define S_base1         #93a1a1
        #define S_base2         #eee8d5
        #define S_base3         #fdf6e3

        *background:            ${colors.background}
        *foreground:            ${colors.body}
        *fadeColor:             ${colors.background}
        *cursorColor:           ${colors.emphasis}
        *pointerColorBackground:${colors.secondary}
        *pointerColorForeground:${colors.emphasis}

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
      config = builtins.replaceStrings
        [ "@underlineWidth@" "@projects@" "@promptFont@" "@promptHeight@" "@background@" "@backgroundHighlight@" "@emphasis@" "@green@" "@xmobarAfterAudio@" ]
        [
          (toString bars.underlineWidth)
          haskellProjects
          (toString bars.main.font)
          (toString bars.main.height)
          colors.background
          colors.backgroundHighlight
          colors.emphasis
          colors.green
          "${xmobarAfterAudio}"
        ]
        (builtins.readFile ./xmonad.hs);
    };
  };

  # Is needed for teamviewer for example.
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    amnezia-vpn
    audacity
    brightnessctl
    feh
    google-chrome
    libreoffice
    scrot
    slack
    steam
    steam-run
    telegram-desktop
    tigervnc
    qpdf
    unetbootin
    unityhub
    xclip
    xdotool
    zathura
    zoom-us

    # Unity Hub ignores Xft.dpi: scales the whole UI, then the fonts back
    (writeShellScriptBin "unityhub-scaled" ''
      export GDK_SCALE=${toString gdkScale}
      export GDK_DPI_SCALE=${toString (1.0 / gdkScale)}
      exec ${unityhub}/bin/unityhub "$@"
    '')
  ];

  # Is needed for Unity3D
  security.chromiumSuidSandbox.enable = true;

  fonts.packages = with pkgs; [
    corefonts
    nerd-fonts.fira-code
    source-code-pro
  ];
}
