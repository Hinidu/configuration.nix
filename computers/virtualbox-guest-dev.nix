{ config, pkgs, ... }:

{
  imports =
    [ ../modules/boot.nix
      ../modules/i18n.nix
      ../modules/standard-packages.nix
      ../modules/xserver.nix
      ../users/hinidu.nix
    ];

  nix.gc.automatic = true;

  time.timeZone = "Europe/Kaliningrad";
}
