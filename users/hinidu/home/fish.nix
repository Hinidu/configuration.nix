{ config, pkgs, ... }:

# Functions with secrets (e.g. ansible-playbook) stay unmanaged in
# ~/.config/fish/functions, so they never end up in this repo.
{
  programs.fish = {
    enable = true;
    functions.ca = {
      wraps = "claude agents";
      description = "claude agents for the current directory";
      body = "claude agents --cwd . $argv";
    };
  };
}
