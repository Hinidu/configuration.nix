# One line of xmobar markup for the second bar line: icon and short name of
# every visible session. The questions themselves are shown by the side panel.
import "sessions" as sessions;

# Short names, so that many sessions fit
def maxNameLength: 25;

# Session text goes through <raw/>, so its "<" can't open an xmobar tag
def raw: "<raw=\(length):\(.)/>";
def color($hex): "<fc=\($hex)>\(.)</fc>";

# $number is what M-s <number> in xmonad jumps to
def render($number):
  sessions::stateStyle as $style
  | ("\($number)" | color("#657B83")) + ("\($style.icon) " | color($style.color))
    + (sessions::sessionName | sessions::truncate(maxNameLength) | raw)
    + (if $style.known then "" else (" (\(.state | tostring | raw))" | color("#657B83")) end);

sessions::visibleSessions
| if length == 0 then "агенты отдыхают" | color("#657B83")
  else to_entries | map(.key as $index | .value | render($index + 1)) | join("  ")
  end
