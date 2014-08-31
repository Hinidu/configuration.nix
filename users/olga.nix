{ config, pkgs, ... }:

{
  users.extraUsers.olga = {
    group = "olga";
    extraGroups = [ "users" ];
    uid = 1001;
    createHome = true;
    home = "/home/olga";
    useDefaultShell = true;
  };

  users.extraGroups.olga.gid = 1001;
}
