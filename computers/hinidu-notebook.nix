{ config, pkgs, ... }:

{
  imports =
    [ ../modules/env.nix
      ../modules/i18n.nix
      ../modules/misc.nix
      ../modules/openvpn-client.nix
      ../modules/standard-packages.nix
      ../modules/xserver.nix
      ../users/hinidu.nix
    ];

  #fileSystems."/".options = ["defaults" "noatime" "discard" "inline_xattr"];
  #fileSystems."/boot".options = ["defaults" "noatime" "discard"];

  networking.hostName = "hinidu_notebook";
  networking.firewall.enable = false;
  networking.wireless = {
    enable = true;

    userControlled.enable = true;

    secretsFile = "/etc/nixos/wifi-secrets.env";

    networks = {
      platto = {
        pskRaw = "ext:psk_home";
      };

      "iPhone (Pavel)" = {
        priority = 10;
        pskRaw = "ext:psk_iphone";
      };
    };
  };

  boot.supportedFilesystems = ["exfat"];
}
