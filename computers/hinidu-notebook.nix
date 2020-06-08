{ config, pkgs, ... }:

{
  imports =
    [ ../modules/env.nix
      ../modules/hosts.nix
      ../modules/i18n.nix
      ../modules/misc.nix
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
    platto = {
      pskRaw = "a221a823136bc15fa6c4fd919612c72113915fe9fa4582d6feda6d98bcf15814";
    };
  };

  services.transmission.enable = true;
  services.transmission.settings = {
    download-dir = "/media/movies/";
    incomplete-dir-enabled = false;
    rpc-whitelist = "127.0.0.1,192.168.1.*";
    umask = 2;
  };
}
