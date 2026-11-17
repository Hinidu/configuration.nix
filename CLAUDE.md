# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Personal NixOS system configuration as a flake (channels disabled). nixpkgs (`nixos-26.05`) and
home-manager (`release-26.05`, must match) are inputs of `flake.nix`, pinned in `flake.lock`:
`nix flake update` moves them to the branches' latest commits, upgrading NixOS means changing both
branch names. Packages are installed declaratively only, not via `nix-env`.

## Checking changes

The user applies the config themselves (`sudo nixos-rebuild switch`, which picks
`nixosConfigurations.<hostname>` from `/etc/nixos/flake.nix`), so don't run it. To verify that the
config evaluates and see what would be built:

```sh
nixos-rebuild dry-build
```

- It must run outside the Bash sandbox (the sandbox hides parts of `/nix/var/nix/profiles`).
- A flake sees only files known to git: `git add -N` every new file, or evaluation says it doesn't
  exist.
- Treat new evaluation warnings (renamed/obsolete options) as something to report.

Formatter: `nixpkgs-fmt` (language server: `nil`).

A new machine is installed with `install.sh <host>` from the NixOS installer; its header lists what
to prepare first.

## Structure

- `flake.nix` lists the hosts in `nixosConfigurations`, each built from `computers/<host>/`; the
  attribute name must equal the host's `networking.hostName`.
- `computers/<host>/default.nix` is the per-host entry point: it picks the set of `modules/` and
  `users/` to import and holds host-only settings (hostname, boot loader, network interfaces,
  `stateVersion`, Wi-Fi networks, and the screen: `display.dpi`/`display.height` from
  `modules/display.nix`, which every desktop size is derived from). Next to it is the host's
  generated `hardware-configuration.nix`. The active host is `hinidu-notebook`.
- New hosts describe their disk with `modules/encrypted-disk.nix` (disko: LUKS2 + btrfs), which
  also provides their `fileSystems`, so their `hardware-configuration.nix` is generated with
  `--no-filesystems`. `hinidu-notebook` predates it and keeps its unencrypted XFS.
- `modules/` contains shared feature modules; most changes go to `modules/standard-packages.nix`
  (system packages, `programs.*`, nix-ld libraries). `environment.systemPackages` is kept in
  alphabetical order; insert new packages at their sorted position.
- `users/hinidu/default.nix` defines the single user; `users/hinidu/home/` is that user's
  Home Manager config (dotfiles); its NixOS module comes from the flake input via `specialArgs.inputs`.

Known stale bits: `computers/hinidu-pc.nix` and `computers/virtualbox-guest-dev.nix` aren't in the
flake and wouldn't evaluate (the latter imports `modules/boot.nix`, which no longer exists).

## Secrets

`wifi-secrets.env` (gitignored, readable only by `root`/`wpa_supplicant`) contains Wi-Fi PSKs
referenced as `ext:psk_*` in `computers/hinidu-notebook/default.nix`. Don't read it or commit
secrets: everything under git is copied into the world-readable Nix store on evaluation. Secrets
are referenced as runtime paths (strings), never as Nix paths.
