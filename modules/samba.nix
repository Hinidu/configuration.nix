{ config, pkgs, ... }:

{
  services.samba = {
    enable = true;
    shares = {
      movies =
        { path = "/media/tmp/movies";
          "read only" = "yes";
          browseable = "yes";
          "guest ok" = "no";
          "valid users" = "hinidu";
        };
    };
    extraConfig = ''
      guest account = nobody
      map to guest = bad user
    '';
  };
}
