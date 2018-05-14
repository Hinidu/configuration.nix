{ config, pkgs, ... }:

{
  imports =
    [ ../modules/boot.nix
      ../modules/i18n.nix
      ../modules/misc.nix
      ../modules/standard-packages.nix
      ../modules/virtualbox-host.nix
      ../modules/xserver.nix
      ../users/hinidu.nix
      ../users/olga.nix
    ];

  fileSystems."/".options = ["defaults" "noatime" "discard" "inline_xattr"];
  fileSystems."/boot".options = ["defaults" "noatime" "discard"];
  fileSystems."/home".options = ["defaults" "noatime" "discard" "inline_xattr"];

  networking.hostName = "hinidu_pc";
  networking.firewall.enable = false;
  networking.wireless.enable = true;

  services.transmission.enable = true;
  services.transmission.settings = {
    download-dir = "/media/tmp/movies/";
    incomplete-dir-enabled = false;
    rpc-whitelist = "127.0.0.1,192.168.1.*";
    umask = 2;
  };

  services.xserver.xrandrHeads = ["VGA1" "HDMI1"];

  boot.extraModprobeConfig = ''
    options snd_hda_intel enable=0,1
  '';

  boot.supportedFilesystems = ["exfat"];

  sound.enableOSSEmulation = false;
}
