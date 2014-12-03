{ config, pkgs, ... }:

{
  users.extraUsers.hinidu = {
    group = "hinidu";
    extraGroups = [ "transmission" "users" "vboxusers" "wheel" ];
    uid = 1000;
    createHome = true;
    home = "/home/hinidu";
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEZqpiPcjrnjF39G042xjZTZ+sNExSlliqE3hmQQ8RqkXSp2Gjm62LVq1JQ6ttWEWCymD3HHFBAL7Cx0u+xttxhjn3P0wP9zHmiBmZrfZ4Da1EsZD+b24K9YJ4iLHYWM4+2MJ9UBWow6ZFJ5/S5FRKqY/MC9KjUwLvfHArOpt0ONt2gz2r+Gk0z0SYhxcFmYKGzh1GxVNxAGhbWo9YN6LGeJkjskc+3Znl3Hl1tpKVrMMZ1bU0/+hiSR4IwOXKL/3fo8A50tqgoTY0E5G9NrhjP8Tz0olXinrXSZszMZ6yysZA0510mxQXnWgF4HT3HFss4LbjOgRVyWgnZ7VcS4wX hinidu@hinidu_notebook" ];
  };

  users.extraGroups.hinidu.gid = 1000;
}
