{ config, lib, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      # vk-laptop confirms each use with a finger instead
      # (computers/vk-laptop/ssh-fingerprint.nix)
      "*".AddKeysToAgent = lib.mkDefault "yes";
      mac = {
        HostName = "Pavels-MacBook-Air.local";
        User = "olgaplatto";
      };
    };
  };
}
