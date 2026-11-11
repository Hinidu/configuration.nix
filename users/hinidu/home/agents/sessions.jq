# Shared logic for the agents bar and panel: which Claude Code background
# sessions to show and how to mark them. The input of every filter here is the
# array of state.json documents the Claude daemon keeps in ~/.claude/jobs/<id>/.

# How long a finished session stays visible
def recentSeconds: 3600;

def epochSeconds: sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601;

def truncate($maxLength):
  if length > $maxLength then .[0:$maxLength - 1] + "…" else . end;

def sessionName: .name // .daemonShort;

# When the session last changed its state as far as you're concerned
def stateSince:
  (if .state == "done" then .lastTerminalAt // .updatedAt else .updatedAt end) | epochSeconds;

def isRecentlyFinished:
  (.lastTerminalAt // .updatedAt) as $finishedAt
  | $finishedAt != null and (now - ($finishedAt | epochSeconds)) < recentSeconds;

# Sessions waiting for you first, finished ones last
def priority:
  if .state == "blocked" then 0 elif .state == "done" then 2 else 1 end;

# "state" is what the session reported in its last message (e.g. it asked a
# question), "tempo" is what it does right now. A session that got its answer
# and runs again keeps the old "blocked" state until it reports anew, so an
# active tempo wins.
#
# A finished session that still has scheduled work (a cron, a background task)
# will wake up by itself, so `claude agents` calls it working. Only watching
# a published artifact doesn't count: `claude agents` shows such a session as
# done.
def hasScheduledWork:
  (.inFlight.kinds // []) | map(select(. != "artifact_watch")) | length > 0;

def actualState:
  if .tempo == "active" then .state = "working"
  elif .state == "done" and hasScheduledWork then .state = "scheduled"
  else .
  end;

def visibleSessions:
  map(actualState | select(.state != "done" or isRecentlyFinished))
  | sort_by(priority, -(.updatedAt | epochSeconds));

# Nerd Font icon and Solarized color of a state (hand, hourglass, clock, check). An unknown state gets a
# warning sign and is shown with its name instead of being guessed.
def stateStyle:
  if .state == "blocked" then { icon: "\uf256", color: "#DC322F", known: true }
  elif .state == "working" then { icon: "\uf252", color: "#B58900", known: true }
  elif .state == "scheduled" then { icon: "\uf017", color: "#268BD2", known: true }
  elif .state == "done" then { icon: "\uf00c", color: "#859900", known: true }
  else { icon: "\uf071", color: "#CB4B16", known: false }
  end;

# "5 мин", "3 ч", "2 д"
def ageText:
  (now - .) as $seconds
  | if $seconds < 60 then "только что"
    elif $seconds < 3600 then "\($seconds / 60 | floor) мин"
    elif $seconds < 86400 then "\($seconds / 3600 | floor) ч"
    else "\($seconds / 86400 | floor) д"
    end;

# Word wrap into an array of lines no longer than $width; a word longer than
# the line is cut into pieces
def wrap($width):
  split("\n")
  | map(
      reduce (split(" ")[] | select(length > 0)) as $word ([];
        if length > 0 and (.[-1] | length) + 1 + ($word | length) <= $width
        then .[-1] += " " + $word
        else . + [$word]
        end)
      | map(. as $line | [range(0; $line | length; $width) | $line[.:. + $width]])
      | add // [])
  | add // [];
