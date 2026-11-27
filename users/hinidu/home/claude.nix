{ config, osConfig, lib, pkgs, ... }:

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

  # YTsaurus MCP server (vk-mcp.json below) with its token from the
  # Bitwarden entry `ytsaurus` (rbw.nix), so no ~/.yt/token on disk. A
  # locked vault brings up pinentry when Claude Code starts the server.
  # Pinned: uvx would otherwise run whatever PyPI serves at startup
  ytsaurusMcpServer = pkgs.writeShellApplication {
    name = "ytsaurus-mcp-server";
    runtimeInputs = [ config.programs.rbw.package pkgs.uv ];
    text = ''
      if ! token=$(rbw get ytsaurus); then
        echo "ytsaurus-mcp-server: can't read the Bitwarden entry 'ytsaurus' (rbw get ytsaurus)" >&2
        exit 1
      fi
      if [ -z "$token" ]; then
        echo "ytsaurus-mcp-server: the Bitwarden entry 'ytsaurus' has an empty password" >&2
        exit 1
      fi
      export MCP_YT_TOKEN="$token"
      exec uvx --from ytsaurus-mcp==0.1.1 mcp_yt_server "$@"
    '';
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

  solarized = osConfig.solarized.colors;

  # Blend two #rrggbb colors: share 0 gives `from`, 1 gives `to`. Solarized
  # has no tints for diff and selection backgrounds, so they are mixed from
  # an accent and the background
  mix = from: to: share:
    let
      channels = color: map (offset: lib.fromHexString (builtins.substring offset 2 color)) [ 1 3 5 ];
      blendChannel = fromChannel: toChannel:
        builtins.floor (fromChannel + (toChannel - fromChannel) * share + 0.5);
      toHexByte = channel: lib.fixedWidthString 2 "0" (lib.toLower (lib.toHexString channel));
    in
    "#" + lib.concatMapStrings toHexByte (lib.zipListsWith blendChannel (channels from) (channels to));

  # Animated highlights pulse towards the lightest tone in both variants
  shimmer = color: mix color solarized.base3 0.4;

  # Every color key of Claude Code 2.1.322's built-in themes, so nothing
  # falls back to the stock palette
  solarizedTheme = with solarized; {
    name = "Solarized";
    base = osConfig.solarized.variant;
    overrides = {
      text = body;
      inverseText = background;
      inactive = secondary;
      inactiveShimmer = body;
      subtle = secondary;
      promptBorder = secondary;
      promptBorderShimmer = body;

      claude = orange;
      claudeShimmer = shimmer orange;
      clawd_body = orange;
      clawd_background = base03;
      briefLabelClaude = orange;
      briefLabelYou = blue;
      claudeBlue_FOR_SYSTEM_SPINNER = blue;
      claudeBlueShimmer_FOR_SYSTEM_SPINNER = shimmer blue;
      permission = blue;
      permissionShimmer = shimmer blue;
      suggestion = blue;
      remember = blue;
      ide = blue;
      professionalBlue = blue;
      autoAccept = violet;
      autoAcceptShimmer = shimmer violet;
      skill = violet;
      merged = violet;
      effortUltra = violet;
      bashBorder = magenta;
      planMode = cyan;
      background = cyan;
      fastMode = orange;
      fastModeShimmer = shimmer orange;
      chromeYellow = yellow;
      rate_limit_fill = blue;
      rate_limit_empty = secondary;

      success = green;
      error = red;
      warning = yellow;
      warningShimmer = shimmer yellow;

      diffAdded = mix background green 0.25;
      diffRemoved = mix background red 0.25;
      diffAddedDimmed = mix background green 0.12;
      diffRemovedDimmed = mix background red 0.12;
      diffAddedWord = mix background green 0.45;
      diffRemovedWord = mix background red 0.45;

      userMessageBackground = backgroundHighlight;
      userMessageBackgroundHover = mix backgroundHighlight secondary 0.15;
      composerSidebarBackground = backgroundHighlight;
      bashMessageBackgroundColor = mix backgroundHighlight magenta 0.08;
      memoryBackgroundColor = mix backgroundHighlight cyan 0.08;
      selectionBg = mix background blue 0.3;

      red_FOR_SUBAGENTS_ONLY = red;
      orange_FOR_SUBAGENTS_ONLY = orange;
      yellow_FOR_SUBAGENTS_ONLY = yellow;
      green_FOR_SUBAGENTS_ONLY = green;
      cyan_FOR_SUBAGENTS_ONLY = cyan;
      blue_FOR_SUBAGENTS_ONLY = blue;
      purple_FOR_SUBAGENTS_ONLY = violet;
      pink_FOR_SUBAGENTS_ONLY = magenta;

      rainbow_red = red;
      rainbow_orange = orange;
      rainbow_yellow = yellow;
      rainbow_green = green;
      rainbow_blue = cyan;
      rainbow_indigo = blue;
      rainbow_violet = violet;
      rainbow_red_shimmer = shimmer red;
      rainbow_orange_shimmer = shimmer orange;
      rainbow_yellow_shimmer = shimmer yellow;
      rainbow_green_shimmer = shimmer green;
      rainbow_blue_shimmer = shimmer cyan;
      rainbow_indigo_shimmer = shimmer blue;
      rainbow_violet_shimmer = shimmer violet;
    };
  };
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
      theme = "custom:solarized";
      # Claude would run `xdg-mime default`, which fails on the read-only
      # mimeapps.list; the handler below is registered declaratively instead
      disableDeepLinkRegistration = "disable";
    };
  };

  # Prompt keys for ~/.claude.json, Claude Code's mutable per-machine state:
  # settings.json doesn't take them, and /config inside `claude agents`
  # sessions doesn't persist them. Only these keys are merged in, the rest of
  # the file stays as Claude wrote it.
  home.activation.claudeCodeGlobalConfig =
    let
      globalConfigFile = "${config.home.homeDirectory}/.claude.json";
      globalConfig = builtins.toJSON { editorMode = "vim"; };
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      configFile=${lib.escapeShellArg globalConfigFile}
      managedConfig=${lib.escapeShellArg globalConfig}
      if [ -e "$configFile" ]; then
        currentConfig=$(cat "$configFile")
      else
        currentConfig='{}'
      fi
      # Rewrite only when a managed key differs, not on every activation
      if ! printf '%s' "$currentConfig" \
        | ${pkgs.jq}/bin/jq -e --argjson managed "$managedConfig" '. * $managed == .' >/dev/null; then
        mergedConfig=$(printf '%s' "$currentConfig" \
          | ${pkgs.jq}/bin/jq --argjson managed "$managedConfig" '. * $managed')
        run ${pkgs.coreutils}/bin/install -m 600 /dev/stdin "$configFile.hm-tmp" <<< "$mergedConfig"
        run mv "$configFile.hm-tmp" "$configFile"
      fi
    '';

  # Picked by `theme = "custom:solarized"`; Claude Code reads it at startup
  home.file."${config.programs.claude-code.configDir}/themes/solarized.json".text =
    builtins.toJSON solarizedTheme;

  # Sessions under ~/work go through the VK AI proxy on the corporate token
  # instead of the personal subscription; the fish `ca` function passes this
  # file to `claude agents --settings` there. The proxy serves no Opus or
  # Fable, so every model tier maps to what it has. The token itself stays
  # out of the repo: apiKeyHelper reads it at runtime from a 600 file.
  home.file."${config.programs.claude-code.configDir}/vk-proxy-settings.json".text =
    builtins.toJSON {
      model = "sonnet";
      apiKeyHelper = "cat ${config.xdg.configHome}/vk-ai-proxy/token";
      env = {
        ANTHROPIC_BASE_URL = "https://ai-proxy.vk.team";
        ANTHROPIC_CUSTOM_HEADERS = "Plugin-Type: claude-code";
        VK_LLM_PROXY_USER = "p.platto";
        ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-sonnet-5-5";
        ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-5-5";
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-haiku-4-5";
        # Telemetry and error reports would reach Anthropic past the proxy
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      };
    };

  # MCP servers for sessions under ~/work on the work laptop, passed by the
  # fish `ca` function as `claude agents --mcp-config`. Not
  # programs.claude-code.mcpServers: that one is global and needs `package`
  # set, since it wraps the binary.
  home.file."${config.programs.claude-code.configDir}/vk-mcp.json" =
    lib.mkIf (osConfig.networking.hostName == "vk-laptop") {
      text = builtins.toJSON {
        mcpServers = {
          # YTsaurus, read-only tools (Cypress, attributes, schemas, ACLs);
          # the cluster is passed in every call
          yt = {
            type = "stdio";
            command = lib.getExe ytsaurusMcpServer;
          };
        };
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
