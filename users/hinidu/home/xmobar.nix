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
  skyIconPairs = builtins.concatStringsSep ", " (
    pkgs.lib.mapAttrsToList (condition: icon: ''("${condition}", "${icon}")'') skyIcons
  );

  lowBatteryAction = pkgs.writeShellScript "xmobar-low-battery" ''
    # A fixed replace id keeps a single notification instead of one per refresh.
    # xmobar runs this on every refresh while discharging, and never on AC, so
    # the timeout (longer than the refresh) makes it vanish after plugging in.
    exec ${pkgs.libnotify}/bin/notify-send --urgency=critical --replace-id=4242 \
      --expire-time=15000 \
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
             -- <fn=1> for secondary details, to save space on the bar
             , additionalFonts = ["FiraCode Nerd Font 7"]
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
                          -- One bar per core; underlined so idle (empty) cores still show their slot
                          , Run MultiCpu [ "--template", "<fc=#B58900>${glyph "f2db"}</fc> <box type=Bottom color=#93A1A1><vbar0><vbar1><vbar2><vbar3><vbar4><vbar5><vbar6><vbar7></box>"
                                         , "--Low", "20"
                                         , "--High", "50"
                                         , "--normal", "#B58900"
                                         , "--high", "#DC322F"
                                         ] 10
                          -- Above the core count (8) means processes are queuing up
                          , Run Load [ "--template", "<fn=1><load1></fn>"
                                     , "--ddigits", "1"
                                     , "--Low", "4"
                                     , "--High", "8"
                                     , "--normal", "#B58900"
                                     , "--high", "#DC322F"
                                     ] 50
                          -- A low frequency under load means thermal throttling
                          , Run CpuFreq ["--template", "<fn=1><avg>G</fn>", "--ddigits", "1"] 50
                          -- The hungriest processes, to know whom to calm down when the laptop chokes;
                          -- CPU is per core like in top, so 100 means one core fully busy
                          , Run TopProc [ "--template", "<fc=#93A1A1>(</fc><both1><fc=#93A1A1>)</fc>"
                                        , "--High", "50"
                                        , "--high", "#DC322F"
                                        ] 20
                          , Run TopMem [ "--template", "<fc=#93A1A1>(</fc><both1><fc=#93A1A1>)</fc>"
                                       -- Percent of total RAM
                                       , "--High", "20"
                                       , "--high", "#DC322F"
                                       ] 20
                          , Run CoreTemp ["-t", "<fc=#B58900>${glyph "f2c9"}</fc> <core0>°"] 60
                          , Run Memory [ "--template", "<fc=#D33682>${glyph "efc5"}</fc> <usedratio>%"
                                       , "--Low", "50"
                                       , "--High", "80"
                                       , "--normal", "#B58900"
                                       , "--high", "#DC322F"
                                       ] 10
                          -- Heavy swapping is the usual reason the laptop barely breathes
                          , Run Swap [ "--template", "<fc=#D33682>${glyph "f0ec"}</fc> <usedratio>%"
                                     , "--Low", "10"
                                     , "--High", "50"
                                     , "--normal", "#B58900"
                                     , "--high", "#DC322F"
                                     ] 50
                          , Run DynNetwork ["-t", "${glyph "f063"} <rx> ${glyph "f062"} <tx>"] 10
                          , Run Wireless "wlo1" ["-t", "<fc=#CB4B16>${glyph "f1eb"} <essid></fc>"] 60
                          , Run DiskU [("/", "<fc=#DC322F>${glyph "f0a0"}</fc> <usedp>%")] [] 100
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
                                        , "-A", "10"
                                        , "-a", "${lowBatteryAction}"
                                        ] 50
                          , Run Date "<fc=#CB4B16>${glyph "f017"} %a %d.%m %H:%M</fc>" "date" 100
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
             -- Two spaces between widgets; details without an icon of their own
             -- (load, frequency, top processes, traffic) stick to their widget with one
             , template = " <fc=#6c71c4><icon=${./xmobar/nixos.xbm}/></fc> %StdinReader% }{ <fn=1>%uptime%</fn>  %multicpu% %load% %cpufreq% %top%  %coretemp%  %memory% %topmem%  %swap%  %wlo1wi% %dynnetwork%  %disku%  %alsa:default:Master%  %battery%  %date%  %UMKK%  <fc=#859900>${glyph "f11c"} %kbd%</fc> "
             }
    '';
  };
}
