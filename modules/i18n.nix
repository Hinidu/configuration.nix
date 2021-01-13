{ config, pkgs, ... }:

{
  # Select internationalisation properties.
  console = {
    font = "ter-v16v";
    keyMap = "ru";
  };
  i18n.defaultLocale = "ru_RU.UTF-8";
}
