{ pkgs, ... }:

# rbw, a Bitwarden client whose agent keeps the vault unlocked for a while:
# secrets are fetched at runtime (`rbw get <entry>`) instead of lying in
# files. The config is read-only here, so `rbw config set` doesn't work;
# once per machine: `rbw login` (`rbw register` first if Bitwarden asks for
# the API key)
{
  programs.rbw = {
    enable = true;
    settings = {
      email = "hinidu@gmail.com";
      # The graphical pinentry (falling back to curses without a display),
      # as programs without a terminal of their own unlock the vault too:
      # MCP servers that Claude Code starts. Set by store path, so nothing
      # goes on PATH next to pinentry-curses from standard-packages.nix
      pinentry = pkgs.pinentry-gtk2;
      # Seconds without any `rbw get` before the agent forgets the keys
      lock_timeout = 3600;
    };
  };
}
