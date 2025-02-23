{ config, pkgs, ... }:

{
  services.transmission.enable = true;
  services.transmission.settings = {
    download-dir = "/media/torrents/";
    incomplete-dir-enabled = false;
    rpc-whitelist = "127.0.0.1,10.39.119.*";
    umask = 2;
  };
}
