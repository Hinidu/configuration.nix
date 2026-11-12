# Runs a jq filter over the state.json files of all Claude Code background
# sessions: read-states <filter.jq> [jq arguments...]. The filter may import
# modules lying next to it (sessions.jq) and gets $focusedTitle: the title of
# the focused kitty window, empty if the focus is elsewhere; and
# $taskDescriptions: {task id: description} of the background shells that
# finished sessions wait for; $sessionCrons: {session daemonShort: [cron job]}
# (see session-crons.jq).
summary_filter=$1
shift

focused_title=""
if focused_window=$(xdotool getwindowfocus 2>/dev/null) \
    && [[ $(xdotool getwindowclassname "$focused_window" 2>/dev/null) == kitty ]]; then
    focused_title=$(xdotool getwindowname "$focused_window" 2>/dev/null) || focused_title=""
fi

shopt -s nullglob
state_files=("$HOME"/.claude/jobs/*/state.json)

# What the background shells of finished sessions (the "scheduled" ones) wait
# for: the description the session gave the command, found in its transcript
# by the task id. A task never changes its description, so the found one is
# cached; a command run without one (e.g. sent to the background by a timeout)
# is looked up again next time, which is a few milliseconds of grep.
description_cache=${XDG_CACHE_HOME:-$HOME/.cache}/agents-bar/task-descriptions
mkdir -p "$description_cache"

describe_task() {
    local task_id=$1 transcript=$2 tool_use_id description
    [[ -s $description_cache/$task_id || ! -r $transcript ]] && return
    tool_use_id=$(grep -F "$task_id" "$transcript" | jq -r --arg taskId "$task_id" '
        .message.content[]? | select(.type == "tool_result")
        | select(.content | tostring | contains("ID: " + $taskId)) | .tool_use_id' 2>/dev/null | head -n 1) || true
    [[ -n $tool_use_id ]] || return 0
    description=$(grep -F "$tool_use_id" "$transcript" | jq -r --arg toolUseId "$tool_use_id" '
        .message.content[]? | select(.type == "tool_use" and .id == $toolUseId)
        | .input.description // empty' 2>/dev/null | head -n 1) || true
    if [[ -n $description ]]; then
        printf '%s' "$description" > "$description_cache/$task_id"
    fi
}

waiting_tasks=()
if [[ ${#state_files[@]} -gt 0 ]]; then
    mapfile -t waiting_tasks < <(jq -r '
        select(.state == "done") | .linkScanPath as $transcript
        | .fan[]? | select(.doneAt == null and .kind == "shell") | "\(.id)\t\($transcript)"' \
        "${state_files[@]}" 2>/dev/null || true)
fi
task_descriptions='{}'
for waiting_task in "${waiting_tasks[@]}"; do
    task_id=${waiting_task%%$'\t'*}
    describe_task "$task_id" "${waiting_task#*$'\t'}"
    if [[ -s $description_cache/$task_id ]]; then
        task_descriptions=$(jq -c --arg taskId "$task_id" --rawfile description "$description_cache/$task_id" \
            '.[$taskId] = $description' <<< "$task_descriptions")
    fi
done

# The cron jobs of finished sessions that have some: they live only in the
# session's memory, so they are restored from its transcript every time
utc_offset=$(date +%z)
utc_offset_seconds=$(( ${utc_offset:0:1}1 * (10#${utc_offset:1:2} * 3600 + 10#${utc_offset:3:2} * 60) ))
cron_sessions=()
if [[ ${#state_files[@]} -gt 0 ]]; then
    mapfile -t cron_sessions < <(jq -r '
        select(.state == "done" and ((.inFlight.kinds // []) | index("session_cron")))
        | "\(.daemonShort)\t\(.linkScanPath)"' "${state_files[@]}" 2>/dev/null || true)
fi
session_crons='{}'
for cron_session in "${cron_sessions[@]}"; do
    session_id=${cron_session%%$'\t'*}
    transcript=${cron_session#*$'\t'}
    [[ -r $transcript ]] || continue
    crons=$(grep -F -e '"Cron' -e 'Scheduled ' "$transcript" \
        | jq -s -c --argjson utcOffsetSeconds "$utc_offset_seconds" \
            -f "$(dirname "$summary_filter")/session-crons.jq" 2>/dev/null) || continue
    session_crons=$(jq -c --arg sessionId "$session_id" --argjson crons "$crons" \
        '.[$sessionId] = $crons' <<< "$session_crons")
done

jq_command=(jq -L "$(dirname "$summary_filter")" -r --arg focusedTitle "$focused_title"
    --argjson taskDescriptions "$task_descriptions" --argjson sessionCrons "$session_crons"
    "$@" -f "$summary_filter")

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
