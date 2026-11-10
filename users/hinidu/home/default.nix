{ config, pkgs, ... }:

{
  imports = [
    ./fish.nix
    ./git.nix
    ./kitty.nix
    ./mpv.nix
    ./vifm.nix
    ./xmobar.nix
  ];

  home.stateVersion = "26.05";
}
