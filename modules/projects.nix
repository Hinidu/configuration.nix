{ config, lib, ... }:

# The xmonad workspaces of this host, as projects (XMonad.Actions.DynamicProjects):
# M-1… switch to them in this order, a terminal opened on one starts in its
# directory, and an agent session from one of its agentDirectories opens on it
# (M-s <number>). The list is set in computers/<host>.nix; xmonad and the
# agents scripts both read it from here.
let
  project = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.strMatching "[a-z0-9-]+";
        example = "work";
        description = "Workspace name shown on the bar.";
      };

      directory = lib.mkOption {
        type = lib.types.strMatching "[~/].*";
        default = "~";
        example = "~/sources";
        description = "Where terminals and other programs started on the workspace begin; ~ is the home directory.";
      };

      agentDirectories = lib.mkOption {
        type = lib.types.listOf (lib.types.strMatching "[~/].*");
        default = [ ];
        example = [ "~/sources/ricochet" ];
        description = "Claude Code sessions working in these directories (or below them) open on this workspace.";
      };
    };
  };

  names = map (workspace: workspace.name) config.desktop.projects;
in
{
  options.desktop.projects = lib.mkOption {
    type = lib.types.nonEmptyListOf project;
    description = "xmonad workspaces in the order of M-1, M-2, …; at most 9 of them get a key.";
  };

  config.assertions = [
    {
      assertion = lib.length names == lib.length (lib.unique names);
      message = "desktop.projects: workspace names must be unique, got ${toString names}";
    }
    {
      assertion = lib.length names <= 9;
      message = "desktop.projects: only M-1…M-9 exist, got ${toString (lib.length names)} workspaces";
    }
  ];
}
