{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
    ./xmobar.nix
  ];

  home.stateVersion = "26.05";
}
