{ config, osConfig, pkgs, ... }:

let
  colors = osConfig.solarized.colors;
  kitten = "${config.programs.kitty.package}/bin/kitten";

  # Shows file:// image links with icat inside the overlay it runs in, and
  # hands every other URL to xdg-open (the overlay then closes at once).
  openUrl = pkgs.writeShellScript "kitty-open-url" ''
    url="$1"
    if [[ $url == file://* ]]; then
      encodedPath=''${url#file://}
      encodedPath=''${encodedPath#localhost}
      printf -v path '%b' "''${encodedPath//%/\\x}"
      case "''${path,,}" in
        *.png | *.jpg | *.jpeg | *.gif | *.webp | *.bmp)
          exec ${kitten} icat --hold -- "$path"
          ;;
      esac
    fi
    ${pkgs.util-linux}/bin/setsid -f ${pkgs.xdg-utils}/bin/xdg-open "$url" >/dev/null 2>&1
  '';
in
# Relies on Xft.dpi from modules/xserver.nix for the HiDPI font size.
{
  programs.kitty = {
    enable = true;
    font = {
      name = "FiraCode Nerd Font";
      size = 10;
    };

    # Built from modules/solarized.nix rather than kitty-themes: its Solarized
    # Dark uses shifted iTerm colors and a bright black that merges with the
    # background. The layout follows kitty-themes' Solarized_Light.
    settings = {
      foreground = colors.body;
      background = colors.background;
      selection_foreground = colors.emphasis;
      selection_background = colors.backgroundHighlight;
      cursor = colors.body;
      cursor_text_color = colors.background;
      active_border_color = colors.orange;
      inactive_border_color = colors.secondary;
      active_tab_background = colors.background;
      active_tab_foreground = colors.body;
      inactive_tab_background = colors.secondary;
      inactive_tab_foreground = colors.background;

      color0 = colors.base02;
      color1 = colors.red;
      color2 = colors.green;
      color3 = colors.yellow;
      color4 = colors.blue;
      color5 = colors.magenta;
      color6 = colors.cyan;
      color7 = colors.base2;
      # Comments and hints (e.g. fish autosuggestions) must stay readable
      color8 = colors.secondary;
      color9 = colors.orange;
      color10 = colors.base01;
      color11 = colors.base00;
      color12 = colors.base0;
      color13 = colors.violet;
      color14 = colors.base1;
      color15 = colors.base3;
    };

    # The default URL hints skip open-actions.conf (they pass open_url_with
    # explicitly), so images would go to the browser.
    keybindings."ctrl+shift+e" =
      "kitten hints --program \"launch --type=overlay ${openUrl}\"";
  };

  # Clicks on file:// image links (e.g. agents' screenshots) show the image
  # over the current window; any key closes it.
  xdg.configFile."kitty/open-actions.conf".text = ''
    protocol file
    mime image/*
    action launch --type=overlay ${kitten} icat --hold -- ''${FILE_PATH}
  '';
}
