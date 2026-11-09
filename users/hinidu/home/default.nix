{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
    ./terminals.nix
    ./vifm.nix
    ./xmobar.nix
  ];

  home.stateVersion = "26.05";
}
