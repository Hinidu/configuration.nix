{ config, pkgs, ... }:

{
  environment.variables.EDITOR = "nvim";
  environment.variables.GOPATH = "$HOME/go";
}
