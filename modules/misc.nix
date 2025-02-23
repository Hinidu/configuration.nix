{ config, pkgs, ... }:

{
  hardware.cpu.intel.updateMicrocode = true;

  # Is needed for Steam
  hardware.graphics.enable32Bit = true;

  nix.gc.automatic = true;

  time.timeZone = "Europe/Kaliningrad";

  services.openssh.enable = true;

  security.pam.loginLimits = [
    {
      domain = "hinidu";
      type = "-";
      item = "nofile";
      value = "65536";
    }
  ];
}
