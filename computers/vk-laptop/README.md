# vk-laptop: after `install.sh`

What `install.sh vk-laptop` doesn't do: the corporate software that lives outside
the Nix store and git, and the keys bound to this machine's TPM and fingerprint
reader. Keys can't be carried over from an old laptop; they are issued again.
The order matters: each step needs the previous one.

The links to the installers are left out of this public repository: they are on
the corporate docs pages named below.

## 0. Bring along

- `wifi-secrets.env` for `install.sh --wifi-secrets` (see its header);
- the legacy OpenVPN profile and login (the `barbos` `.ovpn` as issued): the
  only way into the corporate network until VKey-x509 is set up in step 6;
- the SSH key (`~/.ssh/id_ed25519`), or register a new one where it's used.

## 1. System

1. `install.sh --wifi-secrets <file> vk-laptop` from the NixOS installer.
2. Secure Boot: the three firmware steps in `modules/secure-boot.nix`, and a
   firmware setup password.
3. Commit and push `computers/vk-laptop/hardware-configuration.nix`.

## 2. Fingerprint

    fprintd-enroll

It asks for the password (a polkit rule in `nac-agent.nix`).

## 3. Corporate network through the legacy VPN

    sudo install -D -m 600 <profile>.ovpn /etc/openvpn/barbos.ovpn
    echo '<login>' | sudo install -m 600 /dev/stdin /etc/openvpn/barbos.username
    sudo systemctl start openvpn-barbos   # password: PIN followed by an OTP

It doesn't come back by itself after a reboot or a dropped connection
(`modules/openvpn-client.nix`). The installers, Fleet, the NAC servers and the
VKey issuer below are reachable only through it. Once VKey's `barbos` VPN runs
(step 6), this one is only the fallback: for issuing VKey certificates again.

The docs server doesn't send its intermediate certificate, so `curl` from the
docs fails with error 60. Install the roots the docs name, or fetch the
intermediate from the AIA URL of the server's certificate and pass
`--cacert` a bundle of it and `/etc/ssl/certs/ca-certificates.crt`.

## 4. Fleet Orbit (osquery)

Docs: NAC → «Установка Osquery в Linux». Its `install.sh` recognizes NixOS: it
unpacks the DEB into `/opt/orbit`, writes the enroll secret to
`/etc/default/orbit` and the unit to `/etc/fleet-orbit/module.nix`, and starts
nothing.

    sudo bash install.sh
    diff /etc/fleet-orbit/module.nix fleet-orbit.nix   # port changes, if any
    sudo systemctl restart orbit

Until then the `orbit` unit keeps restarting every 10 s; that's harmless.
Enrolled when `/opt/orbit/secret-orbit-node-key.txt` appears and `osqueryd`
runs (`pgrep -x osqueryd`). Orbit updates itself in `/opt/orbit` afterwards.

## 5. NAC agent

Docs: «Установка NAC». Its `install.sh` doesn't support NixOS; take the release
archive `nac-agent-v<version>-amd64.tar.gz` the docs link to and check its
SHA-256. The units are in `nac-agent.nix`.

    tar -xzf nac-agent-v<version>-amd64.tar.gz --no-same-owner
    sudo install -D -m 0755 nac-agent-v<version>/usr/bin/nac-agent /opt/nac-agent/bin/nac-agent
    sudo systemctl restart nac-vkey nac-agent

The same two commands update it. It works when every ten minutes
`/var/log/nac-agent/nac-agent.log` says `"msg":"send report status code","code":200`;
the checks are in `nac-checker.log` (`"problem":true` marks a failed one). The
screensaver check fails while nobody is logged in.

## 6. VKey-x509 (VPN and mTLS certificates in the TPM)

Docs: «Выпуск сертификатов в сервисе VKey-X509» (the corporate-device page:
not the personal-device one, whose `login` and approval flow doesn't apply).
Take the client archive `vkey-x509-client-linux-v<version>.tar.gz` it links to.
The system side (TPM, `tss` group, sudo for `resolvectl`) is in `vkey-x509.nix`.

    mkdir -p ~/vpn && cp -r vkey-x509-client-linux-v<version> ~/vpn/
    cd ~/vpn/vkey-x509-client-linux-v<version>
    mkdir -p /tmp/vkey && cp template* /tmp/vkey/
    # As root: reads the TPM EK certificate and SMBIOS into the work dir
    sudo ./vkey-x509-client-linux -confdir /tmp/vkey
    # Through the legacy VPN: browser login with 2FA, then NACBot sends a
    # quick-login PIN to keep. Lays out ~/.local/share/vkey-x509/, ~/.tpm2_pkcs11/,
    # the barbos and barbos-tray user units and the PKCS#11 module in ~/.pki/nssdb.
    ./vkey-x509-client-linux -confdir /tmp/vkey -verbose bootstrap
    sudo setcap cap_net_admin+eip ~/.local/share/vkey-x509/openvpn
    # No tray in xmobar (tray-stub.nix only pretends there is one)
    systemctl --user disable --now barbos-tray
    sudo systemctl stop openvpn-barbos   # the same tun device name
    systemctl --user daemon-reload
    systemctl --user start barbos
    # The NAC agent picks its client certificate only on start: until then it
    # reports with the embedded one
    sudo systemctl restart nac-agent

The NAC log then says `"msg":"Will use TPM/VKey certificate"` with the serial of
the VKey certificate instead of `Will use embedded certificate`. The protected
NAC storage for the VKey key (the `ru.vk.nac.vkey.enroll` polkit action,
`/var/lib/nac-agent/vkey`) is optional and isn't used here.

- Flags go before the subcommand: `login -confdir …`, as some docs have it,
  silently ignores `-confdir`.
- Skip the `/etc/sudoers.d/barbos` line the client prints: NixOS sudo doesn't
  read `sudoers.d`, `vkey-x509.nix` has the rule.
- Every `bootstrap` rewrites `openvpn` (so `setcap` again) and enables
  `barbos-tray` again.
- `barbos` then starts on login and restarts when it exits (drop-ins in
  `vkey-x509.nix`). It works when `journalctl --user -u barbos` says
  "Initialization Sequence Completed" and internal names resolve.
- Chrome picks up the PKCS#11 module only after a full `chrome://restart`.

## 7. Apps

Log in to VK WorkSpace (`packages/vkworkspace.nix`) and VK Calls (the Flatpak in
`default.nix`; its runtime comes from Flathub on activation).

## The old laptop

It stays in Fleet and keeps its VKey certificates until revoked; ask IT what to
do with them.
