{ config, pkgs, ... }:

{
  services.xserver.displayManager.kdm.enable = true;

  services.xserver.desktopManager.kde4.enable = true;

  environment.systemPackages = with pkgs.kde4; [
    kdemultimedia
    kdegraphics
    kdeutils
    applications
    kdegames
    kdeedu
    kdelibs
    kde_baseapps
    kactivities
    kdeartwork
    kde_base_artwork
    kdenetwork
    kdepim
    kdeplasma_addons
    kde_wallpapers
    oxygen_icons
    kdebase_workspace
    l10n.ru
  ];
}
