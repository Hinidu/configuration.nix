{ config, pkgs, ... }:

{
  # Select internationalisation properties.
  i18n = {
    consoleFont = "ter-v16v";
    consoleKeyMap = "ru";
    defaultLocale = "ru_RU.UTF-8";
  };
}
