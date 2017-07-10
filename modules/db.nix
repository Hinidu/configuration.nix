{ config, pkgs, ... }:
{
  services.neo4j.enable = true;
  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql96;
}
