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
