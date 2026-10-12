{ config, pkgs, ... }:

{
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
             , commands = [ Run Uptime ["--template", "<fc=#2AA198>Up:</fc> <days>:<hours>:<minutes>"] 600
                          , Run Cpu [ "--template", "<fc=#B58900>CPU:</fc> <total>"
                                    , "-S", "True"
                                    , "--Low", "20"
                                    , "--High", "50"
                                    , "--normal", "#B58900"
                                    , "--high", "#DC322F"
                                    ] 10
                          , Run CoreTemp ["-t", "<core0>C"] 60
                          , Run Memory [ "--template", "<fc=#D33682>Mem:</fc> <used>MB"
                                       , "--Low", "4096"
                                       , "-H", "6144"
                                       , "--normal", "#B58900"
                                       , "--high", "#DC322F"
                                       ] 10
                          , Run DynNetwork ["-t", "<rx>/<tx>"] 10
                          , Run Wireless "wlo1" ["-t", "<fc=#CB4B16><essid>:</fc>"] 60
                          , Run DiskU [("/", "<fc=#DC322F>Root:</fc> <used>/<size>")] [] 100
                          , Run Battery [ "--template", "<fc=#268bd2><acstatus></fc>: <left>% (<timeleft>)"
                                        , "--Low", "10"
                                        , "--High", "80"
                                        , "--low", "#DC322F"
                                        , "--normal", "#B58900"
                                        , "--high", "#859900"
                                        , "--"
                                        , "-O", "AC"
                                        , "-o", "Bat"
                                        ] 10
                          , Run Date "<fc=#CB4B16>%a %b %_d %H:%M:%S</fc>" "date" 10
                          , Run Weather "UMKK" [ "--template","<tempC>C"
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
             , template = " <fc=#6c71c4><icon=${./xmobar/nixos.xbm}/></fc> %StdinReader% }{ %uptime% %cpu% %coretemp% %memory% %wlo1wi% %dynnetwork% %disku% %battery% %date% %UMKK% <fc=#859900>%kbd%</fc>"
             }
    '';
  };
}
