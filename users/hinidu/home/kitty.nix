{ config, pkgs, ... }:

# Relies on Xft.dpi from modules/xserver.nix for the HiDPI font size.
{
  programs.kitty = {
    enable = true;
    font = {
      name = "FiraCode Nerd Font";
      size = 10;
    };
    themeFile = "Solarized_Light";
  };
}
