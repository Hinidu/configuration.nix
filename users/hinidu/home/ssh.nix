{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*".AddKeysToAgent = "yes";
      mac = {
        HostName = "Pavels-MacBook-Air.local";
        User = "olgaplatto";
      };
    };
  };
}
