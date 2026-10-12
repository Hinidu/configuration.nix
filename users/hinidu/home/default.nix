{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
  ];

  home.stateVersion = "26.05";
}
