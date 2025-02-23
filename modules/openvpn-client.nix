{ config, pkgs, ... }:

{
  services.openvpn.servers = {
    niceplans = {
      autoStart = false;
      config = ''config /etc/openvpn/niceplans.ovpn'';
    };
  };
}
