{ config, lib, ... }:

# The screen of this host and the desktop sizes derived from it: X's dpi, both
# xmobar lines, the agents panel, the workspace underline in xmonad. A host
# sets `display.dpi` and `display.height` in computers/<host>.nix; Home Manager
# modules read the rest as osConfig.display.
let
  cfg = config.display;

  # Points are 1/72 inch at the logical dpi, so everything sized in them keeps
  # its proportions to the fonts on any screen
  pixels = points: builtins.floor (points * cfg.dpi / 72.0 + 0.5);

  # xmobar's automatic height ignores dpi and clips the text, so a bar gets
  # 1.73 of its font size: 48 px for 10 pt at 200 dpi
  bar = fontPoints: {
    font = fontPoints;
    height = pixels (fontPoints * 1.73);
  };
in
{
  options.display = {
    dpi = lib.mkOption {
      type = lib.types.ints.positive;
      example = 96;
      description = "Logical dpi of X (Xft.dpi): the size of fonts and everything scaled with them.";
    };

    height = lib.mkOption {
      type = lib.types.ints.positive;
      example = 1080;
      description = "Screen height in pixels; the agents panel stretches down to it.";
    };

    pixels = lib.mkOption {
      type = lib.types.functionTo lib.types.int;
      readOnly = true;
      default = pixels;
      description = "Converts a size in points into pixels at `display.dpi`.";
    };

    bars = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      default = {
        # The main xmobar line, and the agents line right below it
        main = bar 10;
        agents = bar 8;
        # Marks the current workspace and the focused agent session
        underlineWidth = pixels 1.5;
      };
      description = "Font sizes (pt) and heights (px) of the xmobar lines, width of their underlines (px).";
    };
  };
}
