# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Personal NixOS system configuration (no flakes, channels disabled). nixpkgs comes from a local git
checkout at `/home/hinidu/sources/nixpkgs` (a release tag, detached HEAD), wired in via `nix.nixPath`
in `modules/misc.nix`; upgrading NixOS means checking out a newer tag there. Packages are installed
declaratively only, not via `nix-env`.

## Checking changes

The user applies the config themselves (`sudo nixos-rebuild switch`), so don't run it. To verify that
the config evaluates and see what would be built:

```sh
nixos-rebuild dry-build
```

- It must run outside the Bash sandbox (the sandbox hides parts of `/nix/var/nix/profiles`).
- Treat new evaluation warnings (renamed/obsolete options) as something to report.

Formatter: `nixpkgs-fmt` (language server: `nil`).

## Structure

- `configuration.nix` and `hardware-configuration.nix` are **gitignored** and machine-local.
  `configuration.nix` only holds boot loader, network interface and `stateVersion` settings, and
  imports exactly one file from `computers/`.
- `computers/<host>.nix` is the per-host entry point: it picks the set of `modules/` and `users/`
  to import and holds host-only settings (hostname, Wi-Fi networks, xrandr heads).
  The active host is `hinidu-notebook`.
- `modules/` contains shared feature modules; most changes go to `modules/standard-packages.nix`
  (system packages, `programs.*`, nix-ld libraries).
- `users/hinidu.nix` defines the single user.

Known stale bits: `computers/hinidu-pc.nix` and `computers/virtualbox-guest-dev.nix` aren't used
now; the latter imports `modules/boot.nix`, which no longer exists.

## Secrets

`wifi-secrets.env` (gitignored, readable only by `root`/`wpa_supplicant`) contains Wi-Fi PSKs
referenced as `ext:psk_*` in `computers/hinidu-notebook.nix`. Don't read it or commit secrets.
