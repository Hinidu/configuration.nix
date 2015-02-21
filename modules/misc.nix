{ config, pkgs, ... }:

{
  hardware.cpu.intel.updateMicrocode = true;

  nix.gc.automatic = true;

  time.timeZone = "Europe/Kaliningrad";

  services.openssh.enable = true;
}
