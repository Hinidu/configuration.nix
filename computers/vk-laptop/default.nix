{ config, lib, pkgs, inputs, ... }:

# The work ThinkPad T14 Gen4 (Intel). Installed with `install.sh vk-laptop`,
# which generates hardware-configuration.nix next to this file.
{
  imports =
    [ ./hardware-configuration.nix
      ./fleet-orbit.nix
      ./nac-agent.nix
      ./tray-stub.nix
      ./vkey-x509.nix
      inputs.nix-flatpak.nixosModules.nix-flatpak
      ../../modules/devices.nix
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

  # NAC requires /etc/shadow to be 0600 or stricter, but the users activation
  # step (update-users-groups.pl) rewrites it as 0640 root:shadow on every
  # switch and boot. Nothing reads it via the shadow group: unix_chkpwd, passwd,
  # su and sudo are setuid root wrappers.
  system.activationScripts.shadowPermissions = {
    deps = [ "users" ];
    text = "chmod 0600 /etc/shadow";
  };

  # NAC requires the INPUT chain policy to be DROP or REJECT. The iptables
  # firewall of NixOS leaves the policy at ACCEPT and refuses everything
  # unwanted at the end of its nixos-fw chain, so the effect is the same; this
  # only makes the policy itself say so. The nftables backend has `policy drop`
  # in its own table, but Docker keeps an iptables INPUT chain with ACCEPT next
  # to it. Stopping the firewall restores ACCEPT, as nixos-fw is gone then.
  networking.firewall = {
    extraCommands = "ip46tables -P INPUT DROP";
    extraStopCommands = "ip46tables -P INPUT ACCEPT";
  };

  environment.systemPackages = [
    (pkgs.callPackage ../../packages/vkworkspace.nix { })
    # VK Calls from Flatpak (below) under the name of the binary inside it, as
    # the one exported by Flatpak is its app ID
    (pkgs.writeShellScriptBin "vkcalls" ''
      exec ${config.services.flatpak.package}/bin/flatpak run com.vk.calls "$@"
    '')
  ];

  # Gradle builds of the team's Java 11 projects need a JDK no newer than 11;
  # this also sets JAVA_HOME, which Gradle prefers over java in PATH.
  programs.java = {
    enable = true;
    package = pkgs.jdk11;
  };

  # Flatpak only for VK Calls: its DEB links against the system's Qt 5
  # WebEngine, which nixpkgs no longer has, while the Flatpak bundle carries
  # its own (io.qt.qtwebengine.BaseApp) on the org.kde.Platform 5.15-22.08
  # runtime, which nix-flatpak installs from Flathub, its default remote, on
  # activation (the flatpak-managed-install service).
  #
  # The download page links to latest/vk-calls.flatpak, but each release also
  # stays at <version>/, next to the DEB of the same version, so this pins
  # one. The bundle doesn't carry its version, the DEB does: to update, read
  # it from the head of the latest DEB (the part with its control file), drop
  # the Debian revision (1.44.39190-1 is 1.44.39190), and put it and the hash
  # of its bundle into `version` and `sha256`:
  #
  #   curl -s -r 0-131071 -o /tmp/vk-calls.deb https://vkcalls-native-ac.vk-apps.com/latest/vk-calls-amd64.deb
  #   ar p /tmp/vk-calls.deb control.tar.gz | tar -xzO ./control | grep ^Version
  #   curl -sL https://vkcalls-native-ac.vk-apps.com/<version>/vk-calls.flatpak | sha256sum
  #
  # nix-flatpak reinstalls the app when the hash changes.
  services.flatpak = {
    enable = true;
    packages = [
      (
        let
          version = "1.44.39190";
          sha256 = "b44c614b6300a63e6aebfbc53ca7e8f8e1e151d31c8ae6ad8bc999495ab0abee";
        in
        {
          appId = "com.vk.calls";
          inherit sha256;
          bundle = "${pkgs.fetchurl {
            url = "https://vkcalls-native-ac.vk-apps.com/${version}/vk-calls.flatpak";
            inherit sha256;
          }}";
        }
      )
    ];
  };
  # Flatpak requires a portal; xmonad has none of its own, the GTK one serves
  # the file chooser and the rest
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };
  # The sign-in in the browser hands the result back to VK Calls by
  # vkcalls:// (and vkca://, vkcau://) links. Flatpak's own entry for them is
  # in /var/lib/flatpak/exports/share, which only X sessions started after
  # Flatpak was enabled have in XDG_DATA_DIRS; elsewhere xdg-open finds no
  # handler and the links do nothing. The user's profile is always there, and
  # the read-only mimeapps.list needs the defaults declared anyway.
  home-manager.users.hinidu.xdg =
    let
      schemes = map (scheme: "x-scheme-handler/${scheme}") [ "vkcalls" "vkca" "vkcau" ];
    in
    {
      desktopEntries.vkcalls = {
        name = "VK Calls";
        exec = "vkcalls %U";
        noDisplay = true;
        mimeType = schemes;
      };
      mimeApps.defaultApplications = lib.genAttrs schemes (scheme: "vkcalls.desktop");
    };

  solarized.variant = "dark";

  # 14" 1920x1200 (about 161 real dpi); with the 2.8K OLED panel (2880x1800,
  # about 243 real dpi) use dpi = 168 and height = 1800 instead
  display = {
    dpi = 168;
    height = 1800;
  };

  devices = {
    wifiInterface = "wlp0s20f3";
    acAdapter = "AC";
  };

  # xmonad workspaces, M-1… in this order (modules/projects.nix)
  desktop.projects = [
    { name = "im"; }
    { name = "web"; }
    {
      name = "work";
      directory = "~/work";
      agentDirectories = [ "~/work" ];
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
