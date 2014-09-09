{ config, pkgs, ... }:

{
  services.xserver.desktopManager.xfce.enable = true;

  environment.systemPackages = with pkgs; [
    evince
    xarchiver
  ];
}
