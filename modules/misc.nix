{ config, pkgs, ... }:

{
  hardware.cpu.intel.updateMicrocode = true;

  # Is needed for Steam
  hardware.graphics.enable32Bit = true;

  nix.gc.automatic = true;

  time.timeZone = "Europe/Kaliningrad";

  services.openssh.enable = true;

  security.pam.loginLimits = [
    {
      domain = "hinidu";
      type = "-";
      item = "nofile";
      value = "65536";
    }
  ];

  security.pki.certificates = [
    (builtins.readFile (pkgs.fetchurl {
      url = "https://gu-st.ru/content/lending/russian_trusted_root_ca_pem.crt";
      sha256 = "sha256-k2pD/qbo5SW8wPgazZw9IbT8S5torOp5BtaYAFr8ZQQ="; # Укажите актуальный хэш
    }))
    (builtins.readFile (pkgs.fetchurl {
      url = "https://gu-st.ru/content/lending/russian_trusted_sub_ca_pem.crt";
      sha256 = "sha256-8K5YnzZ3TynvNkj3mEsI1C/M5vH/7rYjbXc9rrJ0TqY="; # Укажите актуальный хэш
    }))
  ];
}
