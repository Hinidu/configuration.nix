# M-s <number> in xmonad: brings up the session with that number (as numbered
# on the agents bar and panel). If a kitty window already shows it, prints the
# window's X id for xmonad to focus. The window is found by its title: an
# attached session names the terminal after itself, with a status sign in
# front ("◐ name", "✳ name"). Otherwise opens the agents of the session's
# directory in a new kitty window with the cursor on the session; xmonad
# focuses the window by itself.
# Usage: agents-focus-window <number>; $filters (the jq filters directory)
# is set by agents.nix in front of this script.
number=$1

session=$(agents-read-states "$filters/select.jq" --argjson number "$number")
if [[ -z $session ]]; then
    notify-send --expire-time=4000 "Агенты" "Нет сессии с номером $number"
    exit 1
fi
IFS=$'\t' read -r session_id session_cwd session_name <<< "$session"

for window_id in $(xdotool search --class kitty); do
    title=$(xdotool getwindowname "$window_id") || continue
    if [[ $title == "$session_name" || $title == *" $session_name" ]]; then
        echo "$window_id"
        exit
    fi
done

# Like the `ca` fish function: agents of the session's directory, so that ←
# from the session returns to them (`claude attach` would return to all
# agents). CLAUDE_AGENTS_SELECT puts the cursor on the session, Enter opens
# it; it's what Claude itself sets when it relaunches the agent view, not a
# documented option, so without it the list just starts at the top.
# xmonad reads this script's output to the end, so the new window must not
# keep it open.
setsid --fork kitty --directory "$session_cwd" \
    env CLAUDE_AGENTS_SELECT="$session_id" claude agents --cwd "$session_cwd" \
    < /dev/null > /dev/null 2>&1
