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
    transmission
    unity3d
    xclip
    zathura
  ];

  fonts.fonts = [ pkgs.terminus_font ];

  services.teamviewer.enable = true;

  # Is needed for Unity3D now.
  security.chromiumSuidSandbox.enable = true;
}
