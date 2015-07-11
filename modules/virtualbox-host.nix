{ config, pkgs, ... }:

{
  nixpkgs.config.virtualbox.enableExtensionPack = true;
  services.virtualboxHost.enable = true;
}
