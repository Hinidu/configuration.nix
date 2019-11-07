{ config, pkgs, ... }:

{
  services.openvpn.servers = {
    barbos = { config = ''config /etc/openvpn/barbos.ovpn''; };
  };
}
