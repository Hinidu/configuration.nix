{ config, pkgs, ... }:

{
  programs.vifm = {
    enable = true;
    extraConfig = builtins.readFile ./vifm/vifmrc;
  };

  xdg.configFile."vifm/colors/solarized.vifm".source = ./vifm/solarized.vifm;
}
