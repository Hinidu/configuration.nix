# Every use of the SSH key in ssh-agent asks for a finger on the reader
# (fprintd in default.nix). A key enters the agent unlocked, and any process
# that reaches the agent's socket could otherwise sign with it, a Claude Code
# session or a hijacked npm package among them.
#
# AddKeysToAgent confirm marks the key so that ssh-agent runs SSH_ASKPASS
# (with SSH_ASKPASS_PROMPT=confirm) before each signature; the script below
# answers with fprintd-verify, and a dunst notification says what is
# waiting. Any other askpass request (a passphrase) goes to the usual
# x11-ssh-askpass dialog. A key added before this took effect stays
# unconfirmed until it is re-added: `ssh-add -D`.
{ lib, pkgs, ... }:
let
  passphraseAskpass = "${pkgs.x11_ssh_askpass}/libexec/x11-ssh-askpass";

  fingerprintAskpass = pkgs.writeShellApplication {
    name = "ssh-askpass-fingerprint";
    runtimeInputs = with pkgs; [ coreutils fprintd gnugrep libnotify ];
    text = ''
      if [ "''${SSH_ASKPASS_PROMPT:-}" != confirm ]; then
        exec ${passphraseAskpass} "$@"
      fi

      # $1 is ssh-agent's question, naming the key. A missing notification
      # daemon mustn't stop the check itself
      notification=$(notify-send --print-id --urgency=critical --app-name=ssh-agent \
        "SSH key requested: touch the fingerprint reader" "''${1:-}") || notification=""

      # Allowed only on an explicit match; no match, a timeout or a busy
      # reader (sudo or the screen locker using it) deny the signature
      if timeout 30 fprintd-verify 2>&1 | grep -q "Verify result: verify-match"; then
        result=allowed
      else
        result=denied
      fi

      notify-send ''${notification:+--replace-id="$notification"} --expire-time=3000 \
        --app-name=ssh-agent "SSH key use $result" || true
      [ "$result" = allowed ]
    '';
  };
in
{
  programs.ssh.askPassword = lib.getExe fingerprintAskpass;
  # Each use is confirmed, so the key may stay in the agent for the whole
  # session instead of asking for the passphrase again every hour
  programs.ssh.agentTimeout = null;

  home-manager.users.hinidu.programs.ssh.settings."*".AddKeysToAgent = "confirm";
}
