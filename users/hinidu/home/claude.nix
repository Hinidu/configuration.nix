{ config, lib, pkgs, ... }:

let
  # Example mods from Anthropic, token-weather among them
  claudeCodePlayground = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "claude-code-playground";
    rev = "569c5283d9a0a7ee7938df85bb32e4f48cbb8c86";
    hash = "sha256-rOT2rtXNPayZQEkd2Gbr+9dxClaloxAOoOlDcZp3VQY=";
  };

  markTerminalUrgent = pkgs.writeShellApplication {
    name = "mark-terminal-urgent";
    runtimeInputs = with pkgs; [ jq xdotool ];
    text = builtins.readFile ./claude/mark-terminal-urgent.sh;
  };

  # Highlight the terminal of a session that waits for input or has finished
  markTerminalUrgentHook = [
    {
      hooks = [
        {
          type = "command";
          command = "${lib.getExe markTerminalUrgent} 2>/dev/null || true";
        }
      ];
    }
  ];
in
{
  programs.claude-code = {
    enable = true;
    # claude-code is installed system-wide in modules/standard-packages.nix
    package = null;
    context = ./claude/CLAUDE.md;
    settings = {
      permissions = {
        defaultMode = "auto";
        # Auto mode approves reads and edits here without allow rules
        additionalDirectories = [ "/tmp" ];
      };
      model = "opus";
      hooks = {
        Notification = markTerminalUrgentHook;
        Stop = markTerminalUrgentHook;
      };
      # Background sessions work in place; worktrees only on request
      worktree.bgIsolation = "none";
      enabledPlugins = {
        "superpowers@anthropic-plugin-directory" = true;
        "claude-md-management@anthropic-plugin-directory" = true;
        "claude-code-setup@anthropic-plugin-directory" = true;
        "token-weather@claude-code-playground-mods" = true;
      };
      extraKnownMarketplaces = {
        claude-code-playground-mods.source = {
          source = "directory";
          path = "${claudeCodePlayground}/claude-code/mods";
        };
      };
      language = "Русский";
      # Hold space to dictate a prompt
      voice.enabled = true;
      theme = "light";
      # Claude would run `xdg-mime default`, which fails on the read-only
      # mimeapps.list; the handler below is registered declaratively instead
      disableDeepLinkRegistration = "disable";
    };
  };

  # claude-cli:// deep links. Exec goes through PATH, so the entry survives
  # claude-code upgrades (Claude's own entry pins a /nix/store path)
  xdg.desktopEntries.claude-code-url-handler = {
    name = "Claude Code URL Handler";
    comment = "Handle claude-cli:// deep links for Claude Code";
    exec = "claude --handle-uri %u";
    noDisplay = true;
    mimeType = [ "x-scheme-handler/claude-cli" ];
  };
  xdg.mimeApps.defaultApplications."x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
}
