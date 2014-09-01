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
      maxSpeed = "1.0";
      minSpeed = "0.3";
      twoFingerScroll = true;
    };

    displayManager.slim.enable = true;

    # displayManager.lightdm.enable = true;

    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };

    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
    };
  };
}
