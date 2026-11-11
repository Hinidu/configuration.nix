# Text of the conky side panel: every visible session with its full name and,
# for the ones waiting for you, the question. $columns is the panel width in
# characters.
import "sessions" as sessions;

def maxQuestionLines: 6;

# "$" starts a conky variable
def escape: gsub("\\$"; "$$");
def color($hex): "${color \($hex)}\(.)${color}";
# Solarized base01 and base00: readable on the base2 background
def questionColor: color("#586E75");
def ageColor: color("#657B83");

def numberColor: color("#657B83");

# Under the name, after the number and the icon
def indent: "    ";

# $number is what M-s <number> in xmonad jumps to
def render($number):
  sessions::stateStyle as $style
  | (sessions::sessionName | sessions::wrap($columns - 4)) as $nameLines
  | ((.needs // "") | sessions::wrap($columns - 4)) as $questionLines
  | [ ("\($number) " | numberColor) + ("\($style.icon) " | color($style.color)) + ($nameLines[0] | escape) ]
    + ($nameLines[1:] | map(indent + escape))
    + ($questionLines[0:maxQuestionLines] | map(indent + (escape | questionColor)))
    + (if ($questionLines | length) > maxQuestionLines then [indent + ("…" | questionColor)] else [] end)
    + [ indent + (([ (if $style.known then empty else .state | tostring | escape end),
                     (sessions::stateSince | sessions::ageText) ] | join(" · ")) | ageColor) ];

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
