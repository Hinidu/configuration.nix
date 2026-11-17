{ config, pkgs, lib, ... }:

# Login and lock screens. ly asks for the login and password in the text
# console before X starts; in the session xss-lock runs xsecurelock after
# `idleMinutes` without input (the most VK's NAC allows is 10) and before the
# laptop suspends, e.g. when its lid is closed. xsecurelock asks for the same
# password and, unlike i3lock and others, keeps the screen locked even if its
# password prompt crashes.
let
  idleMinutes = 10;
  # xss-lock dims the screen this long before locking it; any input cancels
  dimSeconds = 10;

  colors = config.solarized.colors;

  # Terminus sizes of the console font, in pixels of height
  consoleFontSizes = [ 12 14 16 18 20 22 24 28 32 ];
  # The largest one not above 12 pt at the screen's dpi: 32 at 200 dpi
  consoleFontSize = lib.last
    (lib.filter (size: size <= config.display.pixels 12) consoleFontSizes);

  locker = pkgs.writeShellScript "lock-screen" ''
    export XSECURELOCK_FONT="Source Code Pro:size=14"
    export XSECURELOCK_AUTH_BACKGROUND_COLOR="${colors.background}"
    export XSECURELOCK_AUTH_FOREGROUND_COLOR="${colors.body}"
    export XSECURELOCK_AUTH_WARNING_COLOR="${colors.red}"
    export XSECURELOCK_SHOW_DATETIME=1
    exec ${pkgs.xsecurelock}/bin/xsecurelock
  '';
in
{
  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "matrix";
      bigclock = "en";
      clear_password = true;
    };
  };

  # ly and the LUKS passphrase prompt are drawn in the console, whose default
  # 8x16 font is tiny on a HiDPI screen; early, so the initrd gets it too
  console = {
    earlySetup = true;
    packages = [ pkgs.terminus_font ];
    font = "ter-v${toString consoleFontSize}n";
  };

  # X's screen saver timer is what xss-lock waits for: it fires after the
  # first number of seconds and locks after the second
  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xset}/bin/xset s ${toString (idleMinutes * 60 - dimSeconds)} ${toString dimSeconds}
  '';

  programs.xss-lock = {
    enable = true;
    lockerCommand = "${locker}";
    extraOptions = [
      "--notifier=${pkgs.xsecurelock}/libexec/xsecurelock/dimmer"
      # Suspend waits until the screen is locked, so it's never shown unlocked
      # on wake up
      "--transfer-sleep-lock"
    ];
  };
}
