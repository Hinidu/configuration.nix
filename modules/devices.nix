{ lib, ... }:

# Kernel names of this host's devices that differ between laptops and that
# nothing detects by itself: xmobar's Wireless plugin needs the interface
# (its "" autodetection shows N/A), and its Battery plugin takes the AC
# adapter on faith, silently treating a missing one as being on battery. A
# host sets them in computers/<host>/default.nix; Home Manager modules read
# them as osConfig.devices.
{
  options.devices = {
    wifiInterface = lib.mkOption {
      type = lib.types.str;
      example = "wlp0s20f3";
      description = "The Wi-Fi network interface, as in `ip link`.";
    };

    acAdapter = lib.mkOption {
      type = lib.types.str;
      example = "AC";
      description = "The AC adapter, as in /sys/class/power_supply.";
    };
  };
}
