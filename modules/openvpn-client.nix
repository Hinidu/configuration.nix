{ config, pkgs, ... }:

{
  services.openvpn.servers = {
    vscale = { config = ''config /etc/openvpn/vscale.ovpn''; };
  };
}
