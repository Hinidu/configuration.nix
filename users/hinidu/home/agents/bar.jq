# One line of xmobar markup for the second bar line: icon and short name of
# every visible session. The questions themselves are shown by the side panel.
import "sessions" as sessions;

# $bodyColor, $focusColor: hex without "#", from modules/solarized.nix;
# $underlineWidth: in pixels, from modules/display.nix
def mutedColor: "#\($bodyColor)";

# Short names, so that many sessions fit
def maxNameLength: 25;

# Session text goes through <raw/>, so its "<" can't open an xmobar tag
def raw: "<raw=\(length):\(.)/>";
def color($hex): "<fc=\($hex)>\(.)</fc>";
# The session of the focused window is underlined like the current workspace
# on the main line
def underline: "<box type=Bottom width=\($underlineWidth) color=#\($focusColor)>\(.)</box>";

# $number is what M-s <number> in xmonad jumps to
def render($number):
  sessions::stateStyle as $style
  | sessions::isFocused as $focused
  | ("\($number)" | color(mutedColor)) + ("\($style.icon) " | color($style.color))
    + (sessions::sessionName | sessions::truncate(maxNameLength) | raw)
    + (if $style.known then "" else (" (\(.state | tostring | raw))" | color(mutedColor)) end)
  | if $focused then underline else . end;

sessions::visibleSessions
| if length == 0 then "агенты отдыхают" | color(mutedColor)
  else to_entries | map(.key as $index | .value | render($index + 1)) | join("  ")
  end
