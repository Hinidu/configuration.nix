{ config, pkgs, ... }:

{
  imports = [ <home-manager/nixos> ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Move aside unmanaged files that are in the way instead of failing
    backupFileExtension = "hm-backup";
    users.hinidu = import ./home;
  };

  users.extraUsers.hinidu = {
    isNormalUser = true;
    group = "hinidu";
    extraGroups = [
      "docker"
      "users"
      "vboxusers"
      "wheel"
    ];
    uid = 1000;
    createHome = true;
    home = "/home/hinidu";
    shell = pkgs.fish;
  };

  users.extraGroups.hinidu.gid = 1000;
}
