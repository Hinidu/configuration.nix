# What Claude Code background sessions are doing, at a glance: a second xmobar
# line with short names and a conky side panel (M-a in xmonad) with the full
# names and the questions the sessions wait to have answered.
{ config, osConfig, pkgs, ... }:

let
  colors = osConfig.solarized.colors;
  # conky's text would take a "#" as a comment start, so the jq filters get
  # colors without it
  hex = color: pkgs.lib.removePrefix "#" color;
  # The session of the focused window is marked green, like the current
  # workspace on the main line
  jqColorArgs = "--arg bodyColor ${hex colors.body} --arg focusColor ${hex colors.green}";

  # jq filters; bar.jq and panel.jq import the shared sessions.jq
  filters = ./agents;

  readStates = pkgs.writeShellApplication {
    name = "agents-read-states";
    runtimeInputs = with pkgs; [ coreutils gnugrep jq xdotool ];
    text = builtins.readFile ./agents/read-states.sh;
  };

  xDpi = osConfig.services.xserver.dpi;
  # conky multiplies every size and gap by Xft.dpi / 96 (but not a font's
  # pixelsize), so real pixels are divided back
  conkyPixels = realPixels: builtins.floor (realPixels * 96.0 / xDpi + 0.5);

  # The font of the main xmobar line, 10 pt
  panelFontPixels = builtins.floor (10 * xDpi / 72.0 + 0.5);
  # Lines are wrapped by panel.jq; FiraCode glyphs are 0.6 em wide, so the
  # text area is exactly this many characters wide
  panelColumns = 34;
  panelTextWidth = builtins.ceil (panelColumns * panelFontPixels * 0.6);
  # Icons are a third bigger than the text: at the text size they are smaller
  # than its capitals
  panelIconPixels = builtins.floor (panelFontPixels * 1.3 + 0.5);
  panelMargin = 16;
  # What conky makes of a value in its units: each one is scaled and rounded
  # to real pixels separately
  conkyRealPixels = units: builtins.floor (units * xDpi / 96.0 + 0.5);
  panelMarginReal = conkyRealPixels (conkyPixels panelMargin);
  # Below both xmobar lines (48 + 38 px) down to the bottom of the 2200 px
  # screen; conky counts the position from the screen top, xmonad sets no work area
  panelTop = 86;
  # The text area's top in conky's units, rounded up: conky can't hit every
  # real pixel, and a panel a pixel too high covers the bottom row of the
  # agents bar, where the focused session is underlined
  panelGapY = builtins.ceil ((panelTop + panelMarginReal) * 96.0 / xDpi);
  panelTextHeight = 2200 - (conkyRealPixels panelGapY + panelMarginReal);
  # For panel.jq to put the icons and the text after them on their columns with
  # ''${goto}, which counts from the window edge, not the text area: one
  # character and the margin in conky's units
  panelColumnWidth = panelFontPixels * 0.6 * 96.0 / xDpi;
  panelGotoOrigin = conkyPixels panelMargin;
  # conky lowers the rest of a line to the baseline of its biggest font, so
  # panel.jq raises the line back by this much before and after an icon: half
  # of the extra ascent of the icon font each time (FiraCode's ascent is 1.1 em)
  panelIconShift = conkyPixels ((panelIconPixels - panelFontPixels) * 1.1 / 2);

  # The panel's text. conky cuts an exec command at about 255 characters, and
  # with the store paths and all the arguments this one is longer, so conky
  # gets only the short path of this script
  panelText = pkgs.writeShellScript "agents-panel-text" ''
    exec ${pkgs.lib.getExe readStates} ${filters}/panel.jq \
      --argjson columns ${toString panelColumns} \
      --argjson columnWidth ${toString panelColumnWidth} \
      --argjson gotoOrigin ${toString panelGotoOrigin} \
      --argjson iconShift ${toString panelIconShift} \
      ${jqColorArgs}
  '';

  # M-s <number> in xmonad: the window of the session with that number, or a
  # new one
  focusWindow = pkgs.writeShellApplication {
    name = "agents-focus-window";
    # kitty and claude come from the system PATH
    runtimeInputs = [ readStates ] ++ (with pkgs; [ xdotool libnotify util-linux ]);
    text = "filters=${filters}\n" + builtins.readFile ./agents/focus-window.sh;
  };

  panelConfig = "${config.xdg.configHome}/conky/agents-panel.conf";

  # Started by xmonad, toggled with M-a. conky reserves the space itself
  # (a panel window with struts), so xmonad moves the windows aside on every
  # workspace while it runs.
  agentsPanel = pkgs.writeShellApplication {
    name = "agents-panel";
    runtimeInputs = with pkgs; [ conky procps ];
    text = ''
      panel_command="conky -c ${panelConfig}"
      is_running() { pgrep -u "$(id -u)" -f "$panel_command" > /dev/null; }
      start() { $panel_command --daemonize > /dev/null; }

      case "''${1:-}" in
        start) is_running || start ;;
        toggle) if is_running; then pkill -u "$(id -u)" -f "$panel_command"; else start; fi ;;
        *) echo "usage: agents-panel start|toggle" >&2; exit 1 ;;
      esac
    '';
  };
in
{
  home.packages = [ agentsPanel focusWindow ];

  # Started by xmonad as a second status bar, right below the main one
  xdg.configFile."xmobar/agents.xmobarrc".text = ''
    Config { font = "FiraCode Nerd Font 8"
           , dpi = 200
           -- The highlight background like the side panel: sets both apart from
           -- the main line and the windows
           , bgColor = "${colors.backgroundHighlight}"
           , fgColor = "${colors.emphasis}"
           -- Height, left/right margins, top margin = the main bar's height, bottom margin
           , position = TopHM 38 0 0 48 0
           , lowerOnStart = False
           , hideOnStart = False
           , allDesktops = True
           , overrideRedirect = False
           , persistent = False
           , border = NoBorder
           -- Every 2 seconds; the daemon updates the job states itself
           , commands = [ Run Com "${pkgs.lib.getExe readStates}" ["${filters}/bar.jq", "--arg", "bodyColor", "${hex colors.body}", "--arg", "focusColor", "${hex colors.green}"] "agents" 20 ]
           , sepChar = "%"
           , alignSep = "}{"
           , template = " %agents% }{ "
           }
  '';

  xdg.configFile."conky/agents-panel.conf".text = ''
    conky.config = {
      out_to_x = true,
      out_to_console = false,
      own_window = true,
      own_window_type = 'panel',
      own_window_class = 'AgentsPanel',
      own_window_title = 'agents-panel',
      own_window_colour = '${hex colors.backgroundHighlight}',
      alignment = 'top_left',
      -- The gaps and sizes are of the text area, so the window itself gets
      -- to the screen edge with the margin
      gap_x = ${toString (conkyPixels panelMargin)},
      gap_y = ${toString panelGapY},
      minimum_width = ${toString (conkyPixels panelTextWidth)},
      maximum_width = ${toString (conkyPixels panelTextWidth)},
      minimum_height = ${toString (conkyPixels panelTextHeight)},
      border_inner_margin = ${toString (conkyPixels panelMargin)},
      border_width = 0,
      -- 1 by default, it would move the window past the margins by 2 px
      border_outer_margin = 0,
      use_xft = true,
      font = 'FiraCode Nerd Font:pixelsize=${toString panelFontPixels}',
      -- The panel header
      font1 = 'FiraCode Nerd Font:bold:pixelsize=${toString panelFontPixels}',
      -- Icons
      font2 = 'FiraCode Nerd Font:pixelsize=${toString panelIconPixels}',
      default_color = '${hex colors.emphasis}',
      draw_borders = false,
      draw_shades = false,
      draw_outline = false,
      double_buffer = true,
      update_interval = 2,
      text_buffer_size = 32768,
    }

    conky.text = [[
    ''${execpi 2 ${panelText}}
    ]]
  '';
}
