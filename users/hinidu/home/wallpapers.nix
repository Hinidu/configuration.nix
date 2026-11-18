# Desktop wallpapers from Wallhaven, a new one every `interval` on a random
# topic. In xmonad M-b + likes the shown one (keeps it in ~/wallpapers), M-b -
# dislikes it (never shows it again and shows a new one at once). Only SFW
# images: the same config runs on the work laptop.
{ osConfig, pkgs, ... }:

let
  interval = "30min";

  # Topics, each a list of Wallhaven search queries: a pick takes a random
  # topic, then a random query of it, so a topic with more queries doesn't come
  # up more often. Every query must find something at the screen's resolution,
  # or `wallpaper next` fails
  topics = {
    space = [ "space" ];
    desert = [ "desert" ];
    mountains = [ "mountains" ];
    # "Dune" alone also finds plain sand dunes, the film's tag only the film
    dune = [ "Dune (movie)" "Dune" ];
    marvel = [ "Marvel Comics" ];
    women = [ "women" ];
  };

  wallpaper = pkgs.writeShellApplication {
    name = "wallpaper";
    runtimeInputs = with pkgs; [ coreutils curl feh findutils gnused imagemagick jq libnotify systemd util-linux xdotool xprop xrandr ];
    text = ''
      topics_file=${pkgs.writeText "wallpaper-topics.json" (builtins.toJSON topics)}
      background="${osConfig.solarized.colors.background}"
    '' + builtins.readFile ./wallpaper.sh;
  };

  session = "graphical-session.target";
in
{
  home.packages = [ wallpaper ];

  # Started by the timer and by `wallpaper dislike`, through systemd so that
  # the two never run at once; either start postpones the timer's next one
  systemd.user.services.wallpaper = {
    Unit = {
      Description = "Next wallpaper from Wallhaven";
      After = [ session ];
      PartOf = [ session ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${wallpaper}/bin/wallpaper next";
    };
  };

  systemd.user.timers.wallpaper = {
    Unit = {
      Description = "Next wallpaper from Wallhaven every ${interval}";
      PartOf = [ session ];
    };
    Timer = {
      OnActiveSec = interval;
      OnUnitActiveSec = interval;
    };
    Install.WantedBy = [ session ];
  };

  # At login the last wallpaper comes back at once, even offline
  systemd.user.services.wallpaper-restore = {
    Unit = {
      Description = "Last wallpaper from Wallhaven";
      After = [ session ];
      PartOf = [ session ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${wallpaper}/bin/wallpaper restore";
    };
    Install.WantedBy = [ session ];
  };
}
