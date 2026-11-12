# Runs a jq filter over the state.json files of all Claude Code background
# sessions: read-states <filter.jq> [jq arguments...]. The filter may import
# modules lying next to it (sessions.jq) and gets $focusedTitle: the title of
# the focused kitty window, empty if the focus is elsewhere.
summary_filter=$1
shift

focused_title=""
if focused_window=$(xdotool getwindowfocus 2>/dev/null) \
    && [[ $(xdotool getwindowclassname "$focused_window" 2>/dev/null) == kitty ]]; then
    focused_title=$(xdotool getwindowname "$focused_window" 2>/dev/null) || focused_title=""
fi

jq_command=(jq -L "$(dirname "$summary_filter")" -r --arg focusedTitle "$focused_title" "$@" -f "$summary_filter")

shopt -s nullglob
state_files=("$HOME"/.claude/jobs/*/state.json)
if [[ ${#state_files[@]} -eq 0 ]]; then
    echo '[]' | "${jq_command[@]}"
    exit
fi

# The daemon may be rewriting a file right now; a retry gets the finished one
for _ in 1 2 3; do
    if "${jq_command[@]}" -s "${state_files[@]}" 2>/dev/null; then
        exit
    fi
    sleep 0.2
done
echo "агенты: не удалось прочитать ~/.claude/jobs"
