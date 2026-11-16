#!/usr/bin/env bash
# Installs this configuration from the NixOS installer onto a new machine.
#
# Before running it:
# - write computers/<host>/default.nix (importing ./hardware-configuration.nix,
#   boot loader, system.stateVersion, networking.hostName = "<host>", and the
#   rest), add the host to nixosConfigurations in flake.nix, and push;
# - partition, format and mount the target at /mnt (with /mnt/boot);
# - connect to the network.
#
# The script generates computers/<host>/hardware-configuration.nix, installs
# from the flake and sets the user's password. Commit and push the hardware
# configuration from the new machine afterwards.
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
config_dir=$target/etc/nixos
host_dir=$config_dir/computers/$host
# users/hinidu/default.nix
user_uid=1000

# The installer may come without git; its own channel is fine for that
if ! command -v git > /dev/null; then
    exec nix-shell -p git --run "$(printf '%q ' "$0" "$@")"
fi

for mount_point in "$target" "$target/boot"; do
    if ! mountpoint -q "$mount_point"; then
        echo "$mount_point is not mounted: partition and mount the target first" >&2
        exit 1
    fi
done

if [[ -e $config_dir ]]; then
    echo "$config_dir already exists; remove it to start over" >&2
    exit 1
fi

git clone "$repository" "$config_dir"

if [[ ! -f $host_dir/default.nix ]]; then
    echo "computers/$host/default.nix is not in the repository: write and push it first" >&2
    exit 1
fi

# Replaces the one from a previous install of this host: the disks were
# formatted again, so their UUIDs are new
nixos-generate-config --root "$target" --show-hardware-config > "$host_dir/hardware-configuration.nix"
# A flake sees only files known to git
git -C "$config_dir" add "computers/$host/hardware-configuration.nix"

# Turns flakes on for this call by itself
nixos-install --flake "$config_dir#$host"

# The configuration sets no password, and without one the user can't log in
echo "Password for hinidu:"
nixos-enter --root "$target" -c 'passwd hinidu'

# Like on the other machines: edited as the user, applied with sudo
chown -R "$user_uid:root" "$config_dir"

echo "Installed. After booting into it, commit and push computers/$host/hardware-configuration.nix."
