{ pkgs, lib, inputs, ... }:

# Secure Boot with keys of our own: the firmware boots only the boot loader and
# kernels signed by them, so nobody can swap the initrd that asks for the LUKS
# passphrase on the unencrypted EFI partition. Lanzaboote takes the place of
# systemd-boot and signs what it puts there.
#
# The first boot of this configuration generates the keys into /var/lib/sbctl
# and puts their enrollment on the EFI partition (/boot/loader/keys/auto);
# then the firmware gets them in three steps:
# 1. In the firmware setup, Security → Secure Boot → Key Management, select
#    "Reset to Setup Mode" (on ThinkPads not "Clear All Secure Boot Keys",
#    which drops the list of revoked signatures too), and save with Secure
#    Boot disabled: AMI firmware (ASUS) enrolls its factory keys when Secure
#    Boot gets enabled in Setup Mode, and then rejects our boot loader. ASUS
#    shows Key Management only while Secure Boot is enabled, so enable it,
#    reset, disable it again.
# 2. Boot: systemd-boot enrolls our keys and reboots; `sudo sbctl status` then
#    says "Setup Mode: ✓ Disabled".
# 3. Enable Secure Boot in the firmware setup; `bootctl status` then says
#    "Secure Boot: enabled (user)".
# Backing out: disable Secure Boot in the firmware setup, which stays reachable.
#
# The private keys are as safe as the disk they're on, so this protects only
# hosts with an encrypted disk, and only with a firmware setup password: without
# one anyone can turn Secure Boot off.
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    autoGenerateKeys.enable = true;
    autoEnrollKeys = {
      enable = true;
      # Only our keys in the firmware, not Microsoft's: their third-party CA
      # signs shim, which boots a distribution's signed kernel with any initrd,
      # e.g. one faking the passphrase prompt. The same CA signs option ROMs,
      # firmware of expansion cards (discrete GPUs, RAID controllers) that the
      # firmware won't run without it. Hosts here have none: before enabling
      # Secure Boot on a host, check that this prints 0
      #   sudo env LC_ALL=C grep -caP '\x02\x00\x00\x00\x04\x00\x00\x80' \
      #     /sys/kernel/security/tpm0/binary_bios_measurements
      # (it counts option ROMs loaded on this boot, measured into PCR 2). The
      # firmware setup has its own graphics, so even if something doesn't start,
      # "Restore Factory Keys" or disabling Secure Boot there brings it back.
      includeMicrosoftKeys = false;
      allowBrickingMyMachine = true;
    };
  };

  # Checking what is signed: `sudo sbctl verify`, `sudo sbctl status`
  environment.systemPackages = [ pkgs.sbctl ];
}
