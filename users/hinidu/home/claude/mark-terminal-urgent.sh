# Sets the X11 urgency hint on the terminal that shows this Claude Code session,
# so xmonad highlights its workspace and M-u jumps to it.
#
# Background sessions run inside the shared daemon, whose $WINDOWID belongs to
# whatever window started the daemon (often long closed). The session is shown
# by a `claude agents` viewer started in the same directory, so its window is
# found by matching the working directory.

session_cwd=$(jq -r '.cwd // empty')

window_ids=()
for proc in /proc/[0-9]*; do
    cmdline=$(tr '\0' ' ' < "$proc/cmdline" 2>/dev/null) || continue
    [[ $cmdline == "claude agents"* ]] || continue
    [[ $(readlink "$proc/cwd") == "$session_cwd" ]] || continue
    viewer_window=$(tr '\0' '\n' < "$proc/environ" 2>/dev/null | sed -n 's/^WINDOWID=//p') || continue
    [[ -n $viewer_window ]] && window_ids+=("$viewer_window")
done

# A plain interactive session runs right in its terminal
if [[ ${#window_ids[@]} -eq 0 && -n ${WINDOWID:-} ]]; then
    window_ids=("$WINDOWID")
fi

for window_id in "${window_ids[@]}"; do
    # The window may be gone already; keep marking the others
    xdotool set_window --urgency 1 "$window_id" || true
done
