#!/usr/bin/env bash
# Installs this configuration from the NixOS installer onto a new machine,
# wiping its disk.
#
# Before running it:
# - write computers/<host>/default.nix: importing ./hardware-configuration.nix
#   and modules/encrypted-disk.nix with `encryptedDisk.device` set (see
#   `lsblk`), modules/secure-boot.nix, system.stateVersion,
#   networking.hostName = "<host>" and the rest; add the host to
#   nixosConfigurations in flake.nix, and push;
# - disable Secure Boot in the firmware setup: the installer isn't signed by
#   keys the firmware knows;
# - connect to the network.
#
# The script generates computers/<host>/hardware-configuration.nix, then
# disko wipes, partitions, encrypts and mounts the disk (it asks to type "yes"
# and for the LUKS passphrase twice), then it installs from the flake and sets
# the user's password. Commit and push the hardware configuration from the new
# machine afterwards.
#
# Options:
#   --disk <device>        install onto this disk instead of the one in
#                          computers/<host> (encryptedDisk.device); the change
#                          stays in the copy of the repository on the new machine
#   --wifi-secrets <file>  copy this file (e.g. from the installer's USB stick)
#                          to /etc/nixos/wifi-secrets.env of the new machine,
#                          readable by root only
#
# Usage: install.sh [--disk <device>] [--wifi-secrets <file>] <host>
set -euo pipefail

usage() {
    echo "usage: $0 [--disk <device>] [--wifi-secrets <file>] <host>, where computers/<host>/ is in the repository" >&2
    exit 1
}

arguments=("$@")
disk=
wifi_secrets=
while [[ $# -gt 0 ]]; do
    case $1 in
        --disk) [[ $# -ge 2 ]] || usage; disk=$2; shift 2 ;;
        --wifi-secrets) [[ $# -ge 2 ]] || usage; wifi_secrets=$(realpath "$2"); shift 2 ;;
        -*) usage ;;
        *) break ;;
    esac
done
[[ $# -eq 1 ]] || usage
host=$1

if [[ -n $wifi_secrets && ! -f $wifi_secrets ]]; then
    echo "$wifi_secrets is not a file" >&2
    exit 1
fi
if [[ -n $disk && ! -b $disk ]]; then
    echo "$disk is not a block device: see lsblk" >&2
    exit 1
fi

target=/mnt
repository=https://github.com/Hinidu/configuration.nix.git
# The disk isn't mounted yet, so the repository waits in the installer's tmpfs
clone=$(mktemp -d)/nixos
host_dir=$clone/computers/$host
config_dir=$target/etc/nixos
system="$clone#nixosConfigurations.\"$host\""
nix=(nix --extra-experimental-features "nix-command flakes")
# users/hinidu/default.nix
user_uid=1000

# The installer may come without git; its own channel is fine for that
if ! command -v git > /dev/null; then
    exec nix-shell -p git --run "$(printf '%q ' "$0" "${arguments[@]}")"
fi

git clone "$repository" "$clone"

if [[ ! -f $host_dir/default.nix ]]; then
    echo "computers/$host/default.nix is not in the repository: write and push it first" >&2
    exit 1
fi

if [[ -n $disk ]]; then
    sed -i -E "s|(encryptedDisk\.device *= *)\"[^\"]*\"|\1\"$disk\"|" "$host_dir/default.nix"
    grep -q "encryptedDisk.device = \"$disk\"" "$host_dir/default.nix" || {
        echo "computers/$host/default.nix has no encryptedDisk.device = \"...\" to replace" >&2
        exit 1
    }
fi

# Without fileSystems and swap: modules/encrypted-disk.nix describes them.
# Replaces the one from a previous install of this host, whose disk is gone.
nixos-generate-config --no-filesystems --show-hardware-config > "$host_dir/hardware-configuration.nix"
# A flake sees only files known to git
git -C "$clone" add "computers/$host/hardware-configuration.nix"

echo "Partitioning the disk as computers/$host describes it..."
"${nix[@]}" run "$system.config.system.build.destroyFormatMount"

nixos-install --flake "$clone#$host"

# The configuration sets no password, and without one the user can't log in
echo "Password for hinidu:"
nixos-enter --root "$target" -c 'passwd hinidu'

mkdir -p "$(dirname "$config_dir")"
cp -a "$clone" "$config_dir"
# Like on the other machines: edited as the user, applied with sudo
chown -R "$user_uid:root" "$config_dir"

if [[ -n $wifi_secrets ]]; then
    install -m 600 -o root -g root "$wifi_secrets" "$config_dir/wifi-secrets.env"
fi

echo "Installed. Boot into it, then put the firmware into Setup Mode with Secure Boot disabled,"
echo "boot once more, and only then enable Secure Boot: see the steps in modules/secure-boot.nix."
echo "Then commit and push computers/$host/hardware-configuration.nix (and default.nix if --disk changed it)."
if [[ -z $wifi_secrets ]]; then
    echo "No --wifi-secrets: put wifi-secrets.env into /etc/nixos (root only) or wpa_supplicant won't start."
fi
