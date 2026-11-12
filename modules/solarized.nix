{ config, lib, ... }:

# One switch for the Solarized variant of the whole desktop: X resources,
# kitty, xmobar, the agents panel, neovim, Claude Code. Home Manager modules
# read the colors as osConfig.solarized.colors.
let
  tones = {
    base03 = "#002b36";
    base02 = "#073642";
    base01 = "#586e75";
    base00 = "#657b83";
    base0 = "#839496";
    base1 = "#93a1a1";
    base2 = "#eee8d5";
    base3 = "#fdf6e3";
  };

  accents = {
    yellow = "#b58900";
    orange = "#cb4b16";
    red = "#dc322f";
    magenta = "#d33682";
    violet = "#6c71c4";
    blue = "#268bd2";
    cyan = "#2aa198";
    green = "#859900";
  };

  # The variants differ only in which base tone plays which role
  roles = {
    light = {
      background = tones.base3;
      backgroundHighlight = tones.base2;
      secondary = tones.base1;
      body = tones.base00;
      emphasis = tones.base01;
    };
    dark = {
      background = tones.base03;
      backgroundHighlight = tones.base02;
      secondary = tones.base01;
      body = tones.base0;
      emphasis = tones.base1;
    };
  };
in
{
  options.solarized = {
    variant = lib.mkOption {
      type = lib.types.enum [ "light" "dark" ];
      description = "Solarized variant: dark normally, light under direct sunlight.";
    };

    colors = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      description = "Base tones, accents and the roles of the chosen variant, as #rrggbb.";
    };
  };

  config.solarized.colors = tones // accents // roles.${config.solarized.variant};
}
