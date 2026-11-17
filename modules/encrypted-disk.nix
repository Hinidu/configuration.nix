{ config, lib, inputs, ... }:

# The whole disk of a host encrypted with LUKS2, described for disko:
# install.sh partitions, formats and mounts it from this description, and
# NixOS gets fileSystems, swap and the LUKS unlock in initrd from it too (so
# the host's hardware-configuration.nix must be generated with
# --no-filesystems). The passphrase is asked for when formatting and at boot.
#
# Layout: a 1 GiB EFI partition (512 MiB filled up with kernels and initrds),
# the rest is LUKS2 with btrfs inside: subvolumes for /, /home and /nix,
# compressed with zstd, and a swap file in a subvolume of its own.
let
  cfg = config.encryptedDisk;
  mountOptions = [ "compress=zstd" "noatime" ];
in
{
  imports = [ inputs.disko.nixosModules.disko ];

  options.encryptedDisk = {
    device = lib.mkOption {
      type = lib.types.strMatching "/dev/.+";
      example = "/dev/nvme0n1";
      description = "The disk to wipe and encrypt whole; see `lsblk` in the installer.";
    };

    swapSize = lib.mkOption {
      type = lib.types.strMatching "[0-9]+[MG]";
      default = "16G";
      description = "Size of the swap file inside the encrypted volume.";
    };
  };

  config.disko.devices.disk.main = {
    type = "disk";
    inherit (cfg) device;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            # The boot loader's random seed must not be readable by users
            mountOptions = [ "umask=0077" ];
          };
        };
        luks = {
          size = "100%";
          # Linux LUKS, so that gdisk and lsblk tell what's inside
          type = "8309";
          content = {
            type = "luks";
            name = "cryptroot";
            settings = {
              # TRIM through to the SSD; reveals which blocks are free, not
              # what is in them
              allowDiscards = true;
              # Lower latency on SSDs: dm-crypt doesn't queue the work
              bypassWorkqueues = true;
            };
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                  inherit mountOptions;
                };
                "/home" = {
                  mountpoint = "/home";
                  inherit mountOptions;
                };
                "/nix" = {
                  mountpoint = "/nix";
                  inherit mountOptions;
                };
                "/swap" = {
                  mountpoint = "/swap";
                  swap.swapfile.size = cfg.swapSize;
                };
              };
            };
          };
        };
      };
    };
  };
}
