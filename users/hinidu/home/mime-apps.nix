{ config, lib, pkgs, ... }:

let
  openAllWith = desktopFile: mimeTypes:
    lib.genAttrs mimeTypes (mimeType: desktopFile);

  # Image, sound and PDF links (e.g. agents' screenshots, opened from kitty or
  # by clicks in Claude Code) would otherwise go to Chrome or whatever claims
  # them
  imageTypes = [ "image/png" "image/jpeg" "image/gif" "image/webp" "image/bmp" ];
  soundTypes = [
    "audio/wav"
    "audio/x-wav"
    "audio/mpeg"
    "audio/ogg"
    "audio/opus"
    "audio/flac"
    "audio/mp4"
    "audio/aac"
  ];
in
{
  # Read-only ~/.config/mimeapps.list: apps can't change defaults behind our back
  xdg.mimeApps = {
    enable = true;
    defaultApplications = openAllWith "feh.desktop" imageTypes
      // openAllWith "mpv.desktop" soundTypes
      // {
      "application/pdf" = "org.pwmt.zathura-pdf-mupdf.desktop";
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
      "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
      "x-scheme-handler/slack" = "slack.desktop";
    };
  };
}
