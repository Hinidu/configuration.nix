{ config, pkgs, ... }:

{
  imports =
    [ ../modules/boot.nix
      ../modules/i18n.nix
      ../modules/misc.nix
      ../modules/standard-packages.nix
      ../modules/virtualbox-host.nix
      ../modules/xserver.nix
      ../users/hinidu.nix
      ../users/olga.nix
    ];

  networking.hostName = "hinidu_notebook";
  networking.wireless.enable = true;

  services.transmission.enable = true;
}
