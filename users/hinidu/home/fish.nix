{ config, lib, pkgs, ... }:

# Functions with secrets (e.g. ansible-playbook) stay unmanaged in
# ~/.config/fish/functions, so they never end up in this repo.
let
  # Work MCP servers (claude.nix), declared only on the work laptop
  workMcpConfig = "${config.programs.claude-code.configDir}/vk-mcp.json";
  hasWorkMcpConfig = config.home.file ? ${workMcpConfig};
in
{
  programs.fish = {
    enable = true;
    functions.ca = {
      wraps = "claude agents";
      description = "claude agents for the current directory";
      # Project settings aren't inherited from parent folders, so under
      # ~/work the VK proxy settings and work MCP servers (claude.nix) are
      # passed explicitly; `claude agents` hands them to every session it
      # dispatches
      body = ''
        set -l work_settings
        if string match -q -- "$HOME/work/*" "$PWD/"
            set work_settings --settings ${config.programs.claude-code.configDir}/vk-proxy-settings.json
            ${lib.optionalString hasWorkMcpConfig "set -a work_settings --mcp-config ${workMcpConfig}"}
        end
        claude agents --cwd . $work_settings $argv
      '';
    };
  };
}
