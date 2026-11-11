# The session with the given number ($number, from 1) as numbered on the bar
# and the panel: its id, working directory and name, separated by tabs;
# nothing if there's no such session.
import "sessions" as sessions;

sessions::visibleSessions | .[$number - 1] // empty
| [.daemonShort, .cwd, sessions::sessionName] | @tsv
