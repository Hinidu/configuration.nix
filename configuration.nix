# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./modules/boot.nix
      ./modules/i18n.nix
      ./modules/networking.nix
      ./modules/standard-packages.nix
      ./modules/xserver.nix
      ./users/hinidu.nix
      ./users/olga.nix
      <nixos/modules/programs/virtualbox.nix>
    ];

  nix.gc.automatic = true;

  time.timeZone = "Europe/Kaliningrad";

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.transmission.enable = true;
}
