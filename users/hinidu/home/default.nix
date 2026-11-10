{ config, pkgs, ... }:

{
  imports = [
    ./claude.nix
    ./fish.nix
    ./git.nix
    ./kitty.nix
    ./mpv.nix
    ./neovim.nix
    ./ssh.nix
    ./vifm.nix
    ./xmobar.nix
  ];

  home.stateVersion = "26.05";
}
