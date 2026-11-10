{ config, pkgs, ... }:

{
  programs.mpv = {
    enable = true;
    config = {
      fullscreen = true;
      # Pick up external audio tracks and subtitles named like the video
      audio-file-auto = "fuzzy";
      sub-auto = "fuzzy";
      # Subtitles stay off until switched on with `j`
      sub = "no";
      # Guess the encoding of Russian subtitles, falling back to cp1251
      sub-codepage = "enca:ru:cp1251";
    };
  };
}
