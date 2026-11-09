{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
    ./kitty.nix
    ./vifm.nix
    ./xmobar.nix
  ];

  home.stateVersion = "26.05";
}
