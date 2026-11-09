{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
    ./terminals.nix
    ./xmobar.nix
  ];

  home.stateVersion = "26.05";
}
