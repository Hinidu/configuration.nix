{ config, pkgs, ... }:

# The work ThinkPad T14 Gen4 (Intel). Installed with `install.sh vk-laptop`,
# which generates hardware-configuration.nix next to this file.
{
  imports =
    [ ./hardware-configuration.nix
      ../../modules/display.nix
      ../../modules/encrypted-disk.nix
      ../../modules/env.nix
      ../../modules/i18n.nix
      ../../modules/misc.nix
      ../../modules/openvpn-client.nix
      ../../modules/projects.nix
      ../../modules/screen-lock.nix
      ../../modules/secure-boot.nix
      ../../modules/solarized.nix
      ../../modules/standard-packages.nix
      ../../modules/xserver.nix
      ../../users/hinidu
    ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # The boot loader is lanzaboote from modules/secure-boot.nix
  boot.loader.efi.canTouchEfiVariables = true;

  # The only NVMe slot of the T14; `install.sh --disk` overrides it after
  # checking `lsblk` in the installer
  encryptedDisk.device = "/dev/nvme0n1";

  # The Goodix 27c6:6594 fingerprint reader (goodixmoc driver of libfprint).
  # fprintd also turns on fprintAuth for every PAM service (login, ly, sudo,
  # the screen locker); a finger is enrolled with `fprintd-enroll`.
  services.fprintd.enable = true;

  solarized.variant = "dark";

  # 14" 1920x1200 (about 161 real dpi); with the 2.8K OLED panel (2880x1800,
  # about 243 real dpi) use dpi = 168 and height = 1800 instead
  display = {
    dpi = 168;
    height = 1800;
  };

  # xmonad workspaces, M-1… in this order (modules/projects.nix)
  desktop.projects = [
    { name = "im"; }
    { name = "web"; }
    {
      name = "work";
      directory = "~/sources";
      agentDirectories = [ "~/sources" ];
    }
    {
      name = "sys";
      directory = "/etc/nixos";
      agentDirectories = [ "/etc/nixos" "~/vpn" ];
    }
  ];

  # Also the name of this host in flake.nix: nixos-rebuild picks it by hostname.
  # The interface is left to the generated hardware-configuration.nix (DHCP on
  # all of them).
  networking.hostName = "vk-laptop";
  networking.wireless = {
    enable = true;

    userControlled = true;

    # Not in git: install.sh --wifi-secrets puts it here, owned by root:wpa_supplicant, mode 640.
    # Every ext:psk_* below is a `psk_*=<passphrase>` line in it.
    secretsFile = "/etc/nixos/wifi-secrets.env";

    networks = {
      VK_Guest = {
        priority = 5;
        pskRaw = "ext:psk_vk_guest";
      };

      platto_5g = {
        priority = 9;
        pskRaw = "ext:psk_home";
      };

      "iPhone (Pavel)" = {
        priority = 10;
        pskRaw = "ext:psk_iphone";
      };
    };
  };

  systemd.services.wpa_supplicant.serviceConfig.BindReadOnlyPaths = [ "/etc/nixos/wifi-secrets.env" ];

  # The release this machine is installed with; never change it on an upgrade
  system.stateVersion = "26.05";
}
