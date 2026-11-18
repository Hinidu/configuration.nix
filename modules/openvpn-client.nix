{ config, lib, pkgs, ... }:

# Corporate VPN. The password is a fixed PIN followed by a one-time code, so
# OpenVPN asks for it on every connect (via systemd-ask-password):
#
#   sudo systemctl start openvpn-barbos   # prompts "Enter Auth Password:"
#   sudo systemctl stop openvpn-barbos
#
# Files prepared by hand (outside git: the .ovpn embeds the tls-auth key, and
# everything under git ends up in the world-readable Nix store):
#   /etc/openvpn/barbos.ovpn      the profile as issued, root:root 0600
#   /etc/openvpn/barbos.username  one line with the login, root:root 0600;
#                                 no password line, so OpenVPN prompts for it
let
  dnsScript = "${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved";
in
{
  services.openvpn.servers.barbos = {
    autoStart = false;
    config = ''
      config /etc/openvpn/barbos.ovpn
    '';
    authUserPass = "/etc/openvpn/barbos.username";
    # Hand the pushed DNS servers and domains to systemd-resolved for the tun link
    up = dnsScript;
    down = dnsScript;
  };

  # A one-time code can't be replayed: an automatic restart (after a dropped
  # connection or after sleep) would only hang on a password prompt nobody
  # sees. Let the unit stop instead and connect again by hand.
  systemd.services.openvpn-barbos.serviceConfig.Restart = lib.mkForce "no";
  services.openvpn.restartAfterSleep = false;
}
