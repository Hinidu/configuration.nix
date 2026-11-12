{ config, pkgs, ... }:

{
  imports =
    [ ../modules/display.nix
      ../modules/env.nix
      ../modules/i18n.nix
      ../modules/misc.nix
      ../modules/openvpn-client.nix
      ../modules/solarized.nix
      ../modules/standard-packages.nix
      ../modules/xserver.nix
      ../users/hinidu
    ];

  #fileSystems."/".options = ["defaults" "noatime" "discard" "inline_xattr"];
  #fileSystems."/boot".options = ["defaults" "noatime" "discard"];

  # "light" for working on the balcony or by the window in direct sunlight
  solarized.variant = "dark";

  # 3300x2200 on 293 mm: about 286 real dpi, scaled down to keep more on screen
  display = {
    dpi = 200;
    height = 2200;
  };

  networking.hostName = "hinidu_notebook";
  networking.wireless = {
    enable = true;

    userControlled = true;

    secretsFile = "/etc/nixos/wifi-secrets.env";

    networks = {
      platto_5g = {
        priority = 9;
        pskRaw = "ext:psk_home";
      };

      platto_vpn_5g = {
        priority = 8;
        pskRaw = "ext:psk_home";
      };

      "iPhone (Pavel)" = {
        priority = 10;
        pskRaw = "ext:psk_iphone";
      };
    };
  };

  systemd.services.wpa_supplicant.serviceConfig.BindReadOnlyPaths = [ "/etc/nixos/wifi-secrets.env" ];

  # mDNS/DNS-SD: resolve *.local names (e.g. the MacBook) and discover LAN
  # services; the module also opens UDP 5353 in the firewall
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  boot.supportedFilesystems = ["exfat"];
}
