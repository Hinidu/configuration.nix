{ config, pkgs, ... }:

{
  programs.vifm = {
    enable = true;
    extraConfig = builtins.readFile ./vifm/vifmrc;
  };

  xdg.configFile."vifm/colors/solarized-light.vifm".source = ./vifm/solarized-light.vifm;
}
