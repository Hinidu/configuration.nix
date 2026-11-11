# What Claude Code background sessions are doing, at a glance: a second xmobar
# line with short names and a conky side panel (M-a in xmonad) with the full
# names and the questions the sessions wait to have answered.
{ config, osConfig, pkgs, ... }:

let
  # jq filters; bar.jq and panel.jq import the shared sessions.jq
  filters = ./agents;

  readStates = pkgs.writeShellApplication {
    name = "agents-read-states";
    runtimeInputs = [ pkgs.jq ];
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
  panelMargin = 16;
  # Below both xmobar lines (48 + 38 px) down to the bottom of the 2200 px
  # screen; conky counts the position from the screen top, xmonad sets no work area
  panelTop = 86;
  panelTextHeight = 2200 - panelTop - 2 * panelMargin;

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
           -- Solarized base2 like the side panel: sets both apart from the
           -- main line and the windows (base3)
           , bgColor = "#eee8d5"
           , fgColor = "#002b36"
           -- Height, left/right margins, top margin = the main bar's height, bottom margin
           , position = TopHM 38 0 0 48 0
           , lowerOnStart = False
           , hideOnStart = False
           , allDesktops = True
           , overrideRedirect = False
           , persistent = False
           , border = NoBorder
           -- Every 2 seconds; the daemon updates the job states itself
           , commands = [ Run Com "${pkgs.lib.getExe readStates}" ["${filters}/bar.jq"] "agents" 20 ]
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
      own_window_colour = 'eee8d5',
      alignment = 'top_left',
      -- The gaps and sizes are of the text area, so the window itself gets
      -- to the screen edge with the margin
      gap_x = ${toString (conkyPixels panelMargin)},
      gap_y = ${toString (conkyPixels (panelTop + panelMargin))},
      minimum_width = ${toString (conkyPixels panelTextWidth)},
      maximum_width = ${toString (conkyPixels panelTextWidth)},
      minimum_height = ${toString (conkyPixels panelTextHeight)},
      border_inner_margin = ${toString (conkyPixels panelMargin)},
      border_width = 0,
      use_xft = true,
      font = 'FiraCode Nerd Font:pixelsize=${toString panelFontPixels}',
      -- The panel header
      font1 = 'FiraCode Nerd Font:bold:pixelsize=${toString panelFontPixels}',
      default_color = '002b36',
      draw_borders = false,
      draw_shades = false,
      draw_outline = false,
      double_buffer = true,
      update_interval = 2,
      text_buffer_size = 32768,
    }

    conky.text = [[
    ''${execpi 2 ${pkgs.lib.getExe readStates} ${filters}/panel.jq --argjson columns ${toString panelColumns}}
    ]]
  '';
}
