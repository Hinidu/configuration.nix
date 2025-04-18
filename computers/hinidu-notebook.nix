{ config, pkgs, ... }:

{
  imports =
    [ ../modules/env.nix
      ../modules/i18n.nix
      ../modules/media-server.nix
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
  networking.wireless.enable = true;
  networking.wireless.networks = {
    WARNING = {
      pskRaw = "8bd116eda8ffea342d351cacba288e5d2e5486730f1813a6481775857cbc9ed0";
    };

    PanzerDog = {
      pskRaw = "1aa52b600a923da39673567df28c800e25c5f2f100941c306831753ef3f768a8";
    };

    platto = {
      pskRaw = "a221a823136bc15fa6c4fd919612c72113915fe9fa4582d6feda6d98bcf15814";
    };

    "iPhone (Павел)" = {
      priority = 10;
      pskRaw = "0f1396b8121cc9e410ce791480b2dad34f997382c34a9169cf5930d0d7ad90c6";
    };
  };

  boot.supportedFilesystems = ["exfat"];
}
