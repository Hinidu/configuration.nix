{ config, pkgs, ... }:

{
  networking.hosts = {
    "94.100.180.130" = [ "sys.mail.ru" ];
  };
}
