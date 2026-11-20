{ config, pkgs, ... }:

# Functions with secrets (e.g. ansible-playbook) stay unmanaged in
# ~/.config/fish/functions, so they never end up in this repo.
{
  programs.fish = {
    enable = true;
    functions.ca = {
      wraps = "claude agents";
      description = "claude agents for the current directory";
      # Project settings aren't inherited from parent folders, so under
      # ~/work the VK proxy settings (claude.nix) are passed explicitly;
      # `claude agents` hands them to every session it dispatches
      body = ''
        set -l proxy_settings
        if string match -q -- "$HOME/work/*" "$PWD/"
            set proxy_settings --settings ${config.programs.claude-code.configDir}/vk-proxy-settings.json
        end
        claude agents --cwd . $proxy_settings $argv
      '';
    };
  };
}
