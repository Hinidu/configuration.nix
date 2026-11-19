# The corporate Fleet agent (Orbit, which runs and updates osquery) required
# by NAC. Verbatim copy of /etc/fleet-orbit/module.nix written by the corporate
# installer from the NAC docs, which puts the binaries into /opt/orbit and the
# enroll secret into /etc/default/orbit: both stay outside git and the Nix
# store. Orbit updates itself in /opt/orbit; the FHS env gives its glibc
# binaries a regular Linux file system layout.
{ pkgs, ... }:
let
  runtime = pkgs.buildFHSEnv {
    name = "fleet-orbit";
    targetPkgs = p: with p; [
      glibc zlib openssl dbus systemdLibs stdenv.cc.cc.lib
    ];
    runScript = pkgs.writeShellScript "fleet-orbit-run" ''
      set -eu
      cd /opt/orbit
      export ORBIT_ROOT_DIR=/opt/orbit
      exec /opt/orbit/bin/orbit/orbit "$@"
    '';
  };
in {
  systemd.services.orbit = {
    description = "Corporate Fleet osquery";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    startLimitIntervalSec = 0;
    serviceConfig = {
      EnvironmentFile = "/etc/default/orbit";
      ExecStart = "${runtime}/bin/fleet-orbit";
      Restart = "always";
      RestartSec = 10;
      KillMode = "control-group";
      TimeoutStopSec = 35;
      CPUQuota = "20%";
      UMask = "0022";
    };
  };
}
