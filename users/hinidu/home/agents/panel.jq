# Text of the conky side panel: every visible session with its full name and,
# for the ones waiting for you, the question. $columns is the panel width in
# characters; $bodyColor and $focusColor are hex without "#", from
# modules/solarized.nix.
import "sessions" as sessions;

def maxQuestionLines: 6;

# "$" starts a conky variable
def escape: gsub("\\$"; "$$");
def color($hex): "${color \($hex)}\(.)${color}";
# Names get the panel's default (emphasized) color, the rest is body text
def questionColor: color("#\($bodyColor)");
def ageColor: color("#\($bodyColor)");

def numberColor: color("#\($bodyColor)");
# The session of the focused window, colored like the current workspace on the
# bar: a green stripe along all its lines in the panel's left margin and a
# green name. The stripe is pulled into the margin by its own width so that the
# text stays in place; offsets are in conky's units (real pixels / 2.08), the
# glyph is 0.6 em = 8 of them.
def focusStripe: "${offset -6}" + ("▎" | color("#\($focusColor)")) + "${offset -2}";

# Under the name, after the number and the icon
def indent: "    ";

def maxTaskLines: 3;

# Material Design icons of Nerd Font (beyond the BMP, which jq can't escape):
# a console window for a background shell, a calendar with a clock for a
# cron job; not hourglasses, which already mean "working"
def shellIcon: [983437] | implode;
def cronIcon: [983280] | implode;

# The schedule of a cron job: when a one-shot one fires ("13.11 06:43"), how
# often a recurring one does ("Every 5 minutes", as CronCreate tells it)
def cronWhen:
  if .recurring then .schedule
  else .nextRunAt | strflocaltime("%d.%m %H:%M")
  end;

# Lines of one thing the session waits for: an icon, then the text wrapped
# under it, at most $maxLines of them
def waitLines($icon; $text; $maxLines):
  ($text | sessions::wrap($columns - 6)) as $lines
  | $lines[0:$maxLines]
  | if ($lines | length) > $maxLines then .[-1] += "…" else . end
  | to_entries
  | map(if .key == 0 then indent + ("\($icon) " | color("#268BD2")) else indent + "  " end
        + (.value | escape | questionColor));

# What a finished session that will wake up by itself waits for: its
# background shells, with how long they run (a stuck loop shows itself by a
# big number) and their description, or the command when there is none; and
# its cron jobs with their schedule and the start of the prompt
def waitingLines:
  if .state != "scheduled" then []
  else
    [ .fan[]? | select(.doneAt == null)
      | (.startedAt / 1000 | sessions::ageText) as $age
      | if $taskDescriptions[.id] then waitLines(shellIcon; "\($age) · \($taskDescriptions[.id])"; maxTaskLines)
        else waitLines(shellIcon; "\($age) · $ \(.label // .kind)" | sessions::truncate($columns - 6); 1)
        end
      | .[] ]
    + [ ($sessionCrons[.daemonShort] // [])[]
        | waitLines(cronIcon; "\(cronWhen) · \(.prompt)"; 2)[] ]
  end;

# $number is what M-s <number> in xmonad jumps to
def render($number):
  sessions::stateStyle as $style
  | sessions::isFocused as $focused
  | (sessions::sessionName | sessions::wrap($columns - 4)
     | map(escape | if $focused then color("#\($focusColor)") else . end)) as $nameLines
  | ((.needs // "") | sessions::wrap($columns - 4)) as $questionLines
  | [ ("\($number) " | numberColor) + ("\($style.icon) " | color($style.color)) + $nameLines[0] ]
    + ($nameLines[1:] | map(indent + .))
    + ($questionLines[0:maxQuestionLines] | map(indent + (escape | questionColor)))
    + (if ($questionLines | length) > maxQuestionLines then [indent + ("…" | questionColor)] else [] end)
    + waitingLines
    + [ indent + (([ (if $style.known then empty else .state | tostring | escape end),
                     (sessions::stateSince | sessions::ageText) ] | join(" · ")) | ageColor) ]
  | if $focused then map(focusStripe + .) else . end;

def count($state): map(select(.state == $state)) | length;

sessions::visibleSessions
| [ "${font1}Агенты${font}${alignr}"
    + ([ ("\uf256 \(count("blocked"))" | color("#DC322F")),
         ("\uf252 \(count("working"))" | color("#B58900")),
         ("\uf017 \(count("scheduled"))" | color("#268BD2")),
         ("\uf00c \(count("done"))" | color("#859900")) ] | join("  ")),
    "" ]
  + (if length == 0 then ["агенты отдыхают" | ageColor]
     else to_entries | map(.key as $index | .value | render($index + 1) + [""]) | add
     end)
| join("\n")
