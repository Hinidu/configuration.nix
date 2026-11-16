{ config, pkgs, ... }:

{
  hardware.cpu.intel.updateMicrocode = true;

  # Is needed for Steam
  hardware.graphics.enable32Bit = true;

  # Without deleting old generations GC frees almost nothing, and /boot (512M)
  # overflows with kernels and initrds of every generation ever built
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };
  boot.loader.systemd-boot.configurationLimit = 10;

  # nixpkgs and home-manager are inputs of flake.nix instead of channels; NixOS
  # points NIX_PATH (<nixpkgs>, nix-shell -p) at the same nixpkgs by itself
  nix.channel.enable = false;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Otherwise every nix-env call (Home Manager activation runs one) recreates
  # ~/.nix-defexpr/channels, and activation warns that channels are disabled
  nix.settings.use-xdg-base-directories = true;

  time.timeZone = "Europe/Kaliningrad";

  security.pam.loginLimits = [
    {
      domain = "hinidu";
      type = "-";
      item = "nofile";
      value = "65536";
    }
  ];

  security.pki.certificates = [
    (builtins.readFile (pkgs.fetchurl {
      url = "https://gu-st.ru/content/lending/russian_trusted_root_ca_pem.crt";
      sha256 = "sha256-k2pD/qbo5SW8wPgazZw9IbT8S5torOp5BtaYAFr8ZQQ="; # Укажите актуальный хэш
    }))
    (builtins.readFile (pkgs.fetchurl {
      url = "https://gu-st.ru/content/lending/russian_trusted_sub_ca_pem.crt";
      sha256 = "sha256-8K5YnzZ3TynvNkj3mEsI1C/M5vH/7rYjbXc9rrJ0TqY="; # Укажите актуальный хэш
    }))
  ];
}
