{ config, pkgs, ... }:

{
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

    desktopManager.xterm.enable = false;

    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
    };
  };

  nixpkgs.config = {
    allowUnfree = true;

    chromium = {
      enableGoogleTalkPlugin = true;
      enablePepperFlash = true;
      enablePepperPdf = true;
    };
  };

  environment.systemPackages = with pkgs; [
    audacity
    chromiumBeta
    libreoffice
    mpv
    rxvt_unicode
    transmission
    xclip
    zathura
  ];

  fonts.fonts = [ pkgs.terminus_font ];
}
