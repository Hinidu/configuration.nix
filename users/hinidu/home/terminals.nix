{ config, pkgs, ... }:

# Two terminals on trial, configured the same way to compare them fairly.
# Both rely on Xft.dpi from modules/xserver.nix for the HiDPI font size.
{
  programs.ghostty = {
    enable = true;
    # The service waits for graphical-session.target, which the plain xmonad
    # session never reaches
    systemd.enable = false;
    settings = {
      font-family = "FiraCode Nerd Font";
      font-size = 10;
      theme = "iTerm2 Solarized Light";
      # xmonad manages windows, the GTK header bar only eats space
      window-decoration = "none";
    };
  };

  programs.kitty = {
    enable = true;
    font = {
      name = "FiraCode Nerd Font";
      size = 10;
    };
    themeFile = "Solarized_Light";
  };
}
