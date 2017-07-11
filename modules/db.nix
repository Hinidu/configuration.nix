{ config, pkgs, ... }:
{
  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql96;
}
