{ config, pkgs, ... }:

{
  hardware.cpu.intel.updateMicrocode = true;

  # Is needed for Steam
  hardware.opengl.driSupport32Bit = true;

  nix.gc.automatic = true;

  time.timeZone = "Europe/Kaliningrad";

  services.openssh.enable = true;
}
