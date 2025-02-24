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

  networking.hostName = "hinidu_pc";
  networking.firewall.enable = false;
  networking.wireless.enable = false;

  services.xserver.xrandrHeads = ["VGA1" "HDMI1"];

  # boot.extraModprobeConfig = ''
  #   options snd_hda_intel enable=0,1
  # '';

  boot.supportedFilesystems = ["exfat"];
}
