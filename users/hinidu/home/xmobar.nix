{ config, pkgs, ... }:

let
  # Nerd Font glyph by its hex code point (BMP only)
  glyph = codePoint: builtins.fromJSON ''"\u${codePoint}"'';

  # Weather sky conditions reported by METAR stations -> Nerd Font weather icons
  skyIcons = {
    "clear" = glyph "e30d";
    "sunny" = glyph "e30d";
    "fair" = glyph "e30d";
    "mostly clear" = glyph "e30d";
    "mostly sunny" = glyph "e30d";
    "partly sunny" = glyph "e302";
    "partly cloudy" = glyph "e302";
    "mostly cloudy" = glyph "e312";
    "cloudy" = glyph "e312";
    "overcast" = glyph "e312";
    "considerable cloudiness" = glyph "e312";
    "obscured" = glyph "e313";
  };
  skyIconPairs = builtins.concatStringsSep ", "
    (pkgs.lib.mapAttrsToList (condition: icon: ''("${condition}", "${icon}")'') skyIcons);

  lowBatteryAction = pkgs.writeShellScript "xmobar-low-battery" ''
    # A fixed replace id keeps a single notification instead of one per refresh
    exec ${pkgs.libnotify}/bin/notify-send --urgency=critical --replace-id=4242 \
      "Батарея почти разряжена" "Пора подключить зарядку"
  '';
in
{
  # Notification daemon, needed for notify-send (low battery warning and others)
  services.dunst.enable = true;

  programs.xmobar = {
    enable = true;

    # Solarized light; xmonad feeds workspaces and the title via stdin
    extraConfig = ''
      Config { font = "FiraCode Nerd Font 10"
             , dpi = 200
             , bgColor = "#fdf6e3"
             , fgColor = "#002b36"
             -- Automatic height ignores dpi and clips the text, so set it explicitly
             , position = TopH 48
             , lowerOnStart = False
             , hideOnStart = False
             , allDesktops = True
             , overrideRedirect = False
             , persistent = False
             , border = NoBorder
             , commands = [ Run Uptime ["--template", "<fc=#2AA198>${glyph "f011"}</fc> <days>:<hours>:<minutes>"] 600
                          , Run Cpu [ "--template", "<fc=#B58900>${glyph "f2db"}</fc> <total>%"
                                    , "--Low", "20"
                                    , "--High", "50"
                                    , "--normal", "#B58900"
                                    , "--high", "#DC322F"
                                    ] 10
                          , Run CoreTemp ["-t", "<fc=#B58900>${glyph "f2c9"}</fc><core0>°"] 60
                          , Run Memory [ "--template", "<fc=#D33682>${glyph "efc5"}</fc> <used>MB"
                                       , "--Low", "4096"
                                       , "-H", "6144"
                                       , "--normal", "#B58900"
                                       , "--high", "#DC322F"
                                       ] 10
                          , Run DynNetwork ["-t", "${glyph "f063"}<rx> ${glyph "f062"}<tx>"] 10
                          , Run Wireless "wlo1" ["-t", "<fc=#CB4B16>${glyph "f1eb"} <essid></fc>"] 60
                          , Run DiskU [("/", "<fc=#DC322F>${glyph "f0a0"}</fc> <used>/<size>")] [] 100
                          , Run Alsa "default" "Master" [ "--template", "<status> <volume>%"
                                                        , "--"
                                                        , "--alsactl=${pkgs.alsa-utils}/bin/alsactl"
                                                        , "-O", "${glyph "f028"}"
                                                        , "-o", "${glyph "f026"}"
                                                        , "-C", "#268bd2"
                                                        , "-c", "#DC322F"
                                                        ]
                          , Run Battery [ "--template", "<acstatus> <left>% (<timeleft>)"
                                        , "--Low", "10"
                                        , "--High", "80"
                                        , "--low", "#DC322F"
                                        , "--normal", "#B58900"
                                        , "--high", "#859900"
                                        , "--"
                                        , "-O", "<fc=#268bd2>${glyph "f1e6"}</fc>"
                                        , "-i", "<fc=#268bd2>${glyph "f1e6"}</fc>"
                                        , "-o", "<fc=#268bd2>${glyph "f242"}</fc>"
                                        , "-A", "5"
                                        , "-a", "${lowBatteryAction}"
                                        ] 50
                          , Run Date "<fc=#CB4B16>${glyph "f017"} %a %b %_d %H:%M:%S</fc>" "date" 10
                          , Run WeatherX "UMKK" [${skyIconPairs}]
                                                [ "--template", "<skyConditionS> <tempC>°"
                                                , "--Low", "10"
                                                , "--High", "20"
                                                , "--low", "#268BD2"
                                                , "--normal", "#B58900"
                                                , "--high", "#DC322F"
                                                ] 600
                          , Run Kbd [("us", "US"), ("ru", "RU")]
                          , Run StdinReader
                          ]
             , sepChar = "%"
             , alignSep = "}{"
             , template = " <fc=#6c71c4><icon=${./xmobar/nixos.xbm}/></fc> %StdinReader% }{ %uptime%  %cpu% %coretemp%  %memory%  %wlo1wi% %dynnetwork%  %disku%  %alsa:default:Master%  %battery%  %date%  %UMKK%  <fc=#859900>${glyph "f11c"} %kbd%</fc> "
             }
    '';
  };
}
