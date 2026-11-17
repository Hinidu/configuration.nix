#!/usr/bin/env bash
# Installs this configuration from the NixOS installer onto a new machine,
# wiping its disk.
#
# Before running it:
# - write computers/<host>/default.nix: importing ./hardware-configuration.nix
#   and modules/encrypted-disk.nix with `encryptedDisk.device` set (see
#   `lsblk`), boot loader, system.stateVersion, networking.hostName = "<host>"
#   and the rest; add the host to nixosConfigurations in flake.nix, and push;
# - connect to the network.
#
# The script generates computers/<host>/hardware-configuration.nix, then
# disko wipes, partitions, encrypts and mounts the disk (it asks to type "yes"
# and for the LUKS passphrase twice), then it installs from the flake and sets
# the user's password. Commit and push the hardware configuration from the new
# machine afterwards.
#
# Usage: install.sh <host>
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <host>, where computers/<host>/ is in the repository" >&2
    exit 1
fi
host=$1

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
    exec nix-shell -p git --run "$(printf '%q ' "$0" "$@")"
fi

git clone "$repository" "$clone"

if [[ ! -f $host_dir/default.nix ]]; then
    echo "computers/$host/default.nix is not in the repository: write and push it first" >&2
    exit 1
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

echo "Installed. After booting into it, commit and push computers/$host/hardware-configuration.nix."
