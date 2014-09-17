{ config, pkgs, ... }:

{
  imports =
    [ ../modules/boot.nix
      ../modules/i18n.nix
      ../modules/networking.nix
      ../modules/standard-packages.nix
      ../modules/virtualbox-host.nix
      ../modules/xserver.nix
      ../users/hinidu.nix
      ../users/olga.nix
    ];

  hardware.cpu.intel.updateMicrocode = true;

  nix.gc.automatic = true;

  time.timeZone = "Europe/Kaliningrad";

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.redshift = {
    enable = true;
    latitude = "51";
    longitude = "-2";
  };

  services.transmission.enable = true;
}
