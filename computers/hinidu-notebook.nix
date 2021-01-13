{ config, pkgs, ... }:

{
  imports =
    [ ../modules/env.nix
      ../modules/i18n.nix
      ../modules/misc.nix
      ../modules/openvpn-client.nix
      ../modules/sound.nix
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
    platto_repeater = {
      pskRaw = "94987dc4da6ebce67d3716eb10add3a3071731b68313865f4f2e1ec80ab4f560";
    };

    WARNING = {
      pskRaw = "8bd116eda8ffea342d351cacba288e5d2e5486730f1813a6481775857cbc9ed0";
    };

    # platto = {
    #   pskRaw = "a221a823136bc15fa6c4fd919612c72113915fe9fa4582d6feda6d98bcf15814";
    # };

    "iPhone (Павел)" = {
      pskRaw = "0f1396b8121cc9e410ce791480b2dad34f997382c34a9169cf5930d0d7ad90c6";
    };
  };

  services.transmission.enable = true;
  services.transmission.settings = {
    download-dir = "/media/movies/";
    incomplete-dir-enabled = false;
    rpc-whitelist = "127.0.0.1,192.168.1.*";
    umask = 2;
  };

  boot.supportedFilesystems = ["exfat"];
}
