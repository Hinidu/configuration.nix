# The session with the given number ($number, from 1) as numbered on the bar
# and the panel: its id, working directory, name and the xmonad workspace of
# its project (empty if none), separated by tabs; nothing if there's no such
# session. $projects: [desktop.projects from modules/projects.nix], as
# --slurpfile gives it.
import "sessions" as sessions;

def expandHome: if startswith("~") then $ENV.HOME + .[1:] else . end;

# The project whose agent directory holds the path; the deepest directory
# wins if they're nested
def workspaceOf($path):
  [ $projects[0][] | .name as $name | .agentDirectories[] | expandHome as $directory
    | select($path == $directory or ($path | startswith($directory + "/")))
    | { name: $name, depth: ($directory | length) } ]
  | max_by(.depth).name // "";

sessions::visibleSessions | .[$number - 1] // empty
| [.daemonShort, .cwd, sessions::sessionName, workspaceOf(.cwd)] | @tsv
