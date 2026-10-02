{ config, pkgs, ... }:

{
  environment.variables.EDITOR = "nvim";

  environment.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk_10}/share/dotnet";
    DOTNET_ROOT_X64 = "${pkgs.dotnet-sdk_10}/share/dotnet";
  };
}
