# Supply-chain hardening for the language package managers (nodejs and uv are
# installed system-wide in modules/standard-packages.nix; only their user
# config lives here). A compromised or typosquatted package usually does its
# damage in an install script, and hijacked releases are typically spotted
# and pulled within days, so:
# - npm runs no lifecycle scripts (preinstall/install/postinstall); a package
#   that really needs one is built explicitly with
#   `npm rebuild --ignore-scripts=false <package>`;
# - npm and uv pick only versions published at least a week ago.
{ ... }:

{
  programs.npm = {
    enable = true;
    package = null;
    settings = {
      ignore-scripts = true;
      # Days
      min-release-age = 7;
    };
  };

  programs.uv = {
    enable = true;
    package = null;
    settings.exclude-newer = "7 days";
  };
}
