{ config, pkgs, ... }:

# settings.json is a read-only link into the store: change settings here, not from Zed's UI.
{
  programs.zed-editor = {
    enable = true;
    mutableUserSettings = false;
    userSettings = {
      vim_mode = true;
      relative_line_numbers = "enabled";

      theme = "Ayu Mirage";

      project_panel.dock = "left";
      outline_panel.dock = "left";
      collaboration_panel.dock = "left";
      git_panel.dock = "left";
      toolbar.quick_actions = false;
      scrollbar.axes = {
        horizontal = false;
        vertical = false;
      };
      gutter = {
        min_line_number_digits = 1;
        folds = false;
        breakpoints = false;
      };
      scroll_beyond_last_line = "off";

      colorize_brackets = true;
      inlay_hints.enabled = true;
      auto_signature_help = true;

      tab_size = 2;
      ensure_final_newline_on_save = false;

      # Unity assets and metadata are YAML
      file_types.YAML = [ "asset" "meta" ];

      languages = {
        Python.format_on_save = "off";
        CSharp = {
          format_on_save = "off";
          tab_size = 4;
        };
        YAML = {
          format_on_save = "off";
          remove_trailing_whitespace_on_save = false;
        };
      };

      # roslyn-ls comes from modules/standard-packages.nix
      lsp.roslyn = {
        binary = {
          path = "Microsoft.CodeAnalysis.LanguageServer";
          arguments = [ "--stdio" "--autoLoadProjects" ];
        };
        initialization_options.FormattingOptions.EnableEditorConfigSupport = true;
      };

      agent = {
        dock = "right";
        # Also writes commit messages and thread titles
        default_model = {
          provider = "zed.dev";
          model = "gpt-5-nano";
        };
      };
      # Keeps a few old Claude Code threads reachable; no new ones are started from Zed
      agent_servers.claude-acp.type = "registry";
    };
  };
}
