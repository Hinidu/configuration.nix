{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        email = "hinidu@gmail.com";
        name = "Pavel Platto";
      };

      alias = {
        st = "status -sb";
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --";
      };

      # Treat spaces before tabs and trailing whitespace as an error
      core.whitespace = "space-before-tab,-indent-with-non-tab,trailing-space";

      # "git push" should push only the current branch to the corresponding remote
      push.default = "current";
    };

    ignores = [
      "**/.claude/settings.local.json"
    ];

    # Machine-local settings with secrets (credentials, tokens in URLs) that
    # must stay out of the world-readable Nix store and this repository
    includes = [
      { path = "~/.config/git/local"; }
    ];
  };
}
