{ config, pkgs, ... }:

{
  imports = [
    ./claude.nix
    ./fish.nix
    ./git.nix
    ./kitty.nix
    ./mime-apps.nix
    ./mpv.nix
    ./neovim.nix
    ./ssh.nix
    ./terraform.nix
    ./vifm.nix
    ./xmobar.nix
    ./zed.nix
  ];

  home.stateVersion = "26.05";
}
