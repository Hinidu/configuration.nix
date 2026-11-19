# What the corporate VKey-x509 client (issues the VPN and mTLS certificates
# with keys in the TPM) needs from the system. The client itself lays out its
# files in the home directory: ~/.local/share/vkey-x509/ (openvpn,
# libtpm2-pkcs11.so, the tray…) and the barbos and barbos-tray user units.
#
# The VPN it sets up is a user unit (`systemctl --user start barbos`) with the
# same tun device name as openvpn-barbos from modules/openvpn-client.nix, so
# only one of them can run at a time.
{ ... }:
{
  # The client creates and uses its keys as the user, through /dev/tpmrm0
  # (the tpm2-tss udev rules give it to the tss group; no tpm2-abrmd needed)
  security.tpm2.enable = true;
  users.users.hinidu.extraGroups = [ "tss" ];

  # The VPN up script (barbos.ovpn.sh) hands the pushed DNS servers and domains
  # of the barbos device to systemd-resolved through sudo, non-interactively.
  # It finds resolvectl in /run/current-system/sw/bin.
  security.sudo.extraRules = [
    {
      users = [ "hinidu" ];
      commands = map
        (subcommand: {
          command = "/run/current-system/sw/bin/resolvectl ${subcommand} barbos *";
          options = [ "NOPASSWD" ];
        })
        [ "dns" "domain" ];
    }
  ];
}
