# The corporate NAC agent: checks the laptop's compliance (osquery, firewall,
# disk encryption, screen lock…) and holds its mTLS key in the TPM (nac-vkey).
# The units, polkit files and log rotation follow `packaging/` of the release
# archive from the NAC docs, whose install.sh writes into /usr/bin and so
# doesn't support NixOS.
#
# The binary is kept outside git and the Nix store, like Orbit's: it depends
# only on glibc and runs through nix-ld. To install or update it, unpack the
# release archive and copy the binary, then restart the services:
#
#   sudo install -D -m 0755 nac-agent-<version>/usr/bin/nac-agent /opt/nac-agent/bin/nac-agent
#   sudo systemctl restart nac-vkey nac-agent
{ config, pkgs, ... }:
let
  binary = "/opt/nac-agent/bin/nac-agent";

  # The agent looks up the tools it inspects (iptables, xset, loginctl,
  # getent…) in PATH, as on a regular distribution
  systemTools = [ config.system.path ];

  # The screensaver check runs `xset q` with DISPLAY taken from logind, but ly
  # opens the PAM session before it picks the display, so logind never learns
  # it. This xset, found first in the agent's PATH, takes DISPLAY and
  # XAUTHORITY from the user's X server and runs the real xset against it.
  xsetFromSession = pkgs.writeShellApplication {
    name = "xset";
    runtimeInputs = [ pkgs.procps ];
    text = ''
      if [ -z "''${DISPLAY:-}" ] && [ -n "''${USER:-}" ]; then
        for xServer in $(pgrep -u "$USER" -x 'X|Xorg'); do
          while IFS= read -r -d "" variable; do
            case "$variable" in
              DISPLAY=* | XAUTHORITY=*) export "''${variable?}" ;;
            esac
          done <"/proc/$xServer/environ"
          if [ -n "''${DISPLAY:-}" ]; then break; fi
        done
      fi
      exec ${pkgs.xset}/bin/xset "$@"
    '';
  };

  vkeyPolicy = pkgs.writeTextDir "share/polkit-1/actions/ru.vk.nac.vkey.policy" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN" "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
    <policyconfig>
      <vendor>VK</vendor>
      <action id="ru.vk.nac.vkey.enroll">
        <description>Connect an existing vkey to protected NAC storage</description>
        <description xml:lang="ru">Подключить существующий ключ VKey к защищённому хранилищу NAC</description>
        <message>Administrator authentication is required to connect your VKey.</message>
        <message xml:lang="ru">Для подключения ключа VKey требуется подтверждение администратора.</message>
        <defaults>
          <allow_any>auth_admin</allow_any>
          <allow_inactive>auth_admin</allow_inactive>
          <allow_active>auth_admin</allow_active>
        </defaults>
      </action>
    </policyconfig>
  '';
in
{
  environment.systemPackages = [ vkeyPolicy ];

  # Changing the enrolled fingerprints counts as changing a key authorization,
  # so `fprintd-enroll` asks for the password
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "net.reactivated.fprint.device.enroll") {
            return polkit.Result.AUTH_ADMIN;
        }
    });
  '';

  # Created before the agent starts: systemd opens the append: log files
  # before it would create a LogsDirectory=
  systemd.tmpfiles.rules = [ "d /var/log/nac-agent 0755 root root -" ];

  systemd.services.nac-agent = {
    description = "NAC agent for Linux";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ xsetFromSession ] ++ systemTools;
    serviceConfig = {
      Type = "simple";
      ExecStart = binary;
      Restart = "always";
      RestartSec = 10;
      StandardOutput = "append:/var/log/nac-agent/nac-agent.log";
      StandardError = "append:/var/log/nac-agent/nac-checker.log";
    };
  };

  systemd.services.nac-vkey = {
    description = "NAC protected vkey operations";
    wantedBy = [ "multi-user.target" ];
    requires = [ "dbus.service" ];
    after = [ "dbus.service" ];
    path = systemTools;
    serviceConfig = {
      Type = "notify";
      ExecStart = "${binary} vkey serve";
      Restart = "on-failure";
      RestartSec = 3;
      User = "root";
      Group = "root";
      UMask = "0077";
      RuntimeDirectory = "nac-agent/vkey";
      RuntimeDirectoryMode = "0755";
      StateDirectory = "nac-agent/vkey";
      StateDirectoryMode = "0700";
      LimitCORE = 0;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      RestrictAddressFamilies = "AF_UNIX";
      DevicePolicy = "closed";
      DeviceAllow = "/dev/tpmrm0 rw";
      ReadWritePaths = [ "/var/lib/nac-agent/vkey" "/run/nac-agent/vkey" ];
    };
  };

  # copytruncate, unlike the release's rule: systemd keeps the log files open
  services.logrotate.settings."/var/log/nac-agent/*.log" = {
    frequency = "daily";
    rotate = 1;
    missingok = true;
    notifempty = true;
    copytruncate = true;
  };
}
