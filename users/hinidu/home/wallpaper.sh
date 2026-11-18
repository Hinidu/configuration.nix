# Desktop wallpapers from Wallhaven (wallhaven.cc): every pick is a random
# image among the most favorited ones for a random query of a random topic, at
# least as large as the screen. `topics_file` (a JSON object: topic name → list
# of search queries) and `background` (the color under the bars) are set by
# wallpapers.nix before this text.
#
# The image fills only the part of the screen that the bars and panels leave
# visible (their struts), so its middle is in the middle of what is seen.
#
#   wallpaper next     show a new one (the systemd timer)
#   wallpaper like     keep the shown one in ~/wallpapers (M-b + in xmonad)
#   wallpaper dislike  never show it again, show a new one now (M-b -)
#   wallpaper refresh  fit the shown one again, after a panel came or went
#   wallpaper restore  show the last one again at login, or a new one

cache="${XDG_CACHE_HOME:-$HOME/.cache}/wallpapers"
# Ids of disliked images: unlike the cache, never thrown away
state="${XDG_STATE_HOME:-$HOME/.local/state}/wallpapers"
saved="$HOME/wallpapers"
api="https://wallhaven.cc/api/v1/search"
# A pick comes from the first pages of the most favorited, 24 per page: deeper
# down even the large topics get dull
top_pages=10
# Downloaded images kept besides the shown one, and ids remembered so that a
# topic doesn't repeat itself soon
kept_images=10
remembered_ids=300

mkdir -p "$cache" "$state"
touch "$cache/history" "$state/disliked"

show() {
  local image="$1"
  ln -sfn "$image" "$cache/current"
  render "$image"
}

# Resolution of the whole X screen, as "2880x1800"
screen_size() {
  local size
  size=$(xrandr --current | sed -n 's/.* current \([0-9]*\) x \([0-9]*\),.*/\1x\2/p')
  if [[ ! $size =~ ^[0-9]+x[0-9]+$ ]]; then
    echo "can't read the screen size from xrandr: '$size'" >&2
    exit 1
  fi
  echo "$size"
}

# Space reserved at the screen edges by the visible windows (xmobar, the
# agents panel), as "left right top bottom": the largest strut on each side
reserved_edges() {
  local left=0 right=0 top=0 bottom=0 window strut
  local -a sides
  for window in $(xdotool search --onlyvisible --name '' || true); do
    strut=$(xprop -id "$window" _NET_WM_STRUT_PARTIAL 2>/dev/null || true)
    [[ $strut == *=* ]] || continue
    IFS=', ' read -r -a sides <<<"${strut#*= }"
    ((sides[0] > left)) && left=${sides[0]}
    ((sides[1] > right)) && right=${sides[1]}
    ((sides[2] > top)) && top=${sides[2]}
    ((sides[3] > bottom)) && bottom=${sides[3]}
  done
  echo "$left $right $top $bottom"
}

# Puts the image on the root window, filling the visible part of the screen.
# Runs one at a time: the timer's pick and a panel toggle may come together
render() {
  local image="$1" size width height left right top bottom visible_width visible_height
  exec {lock}>"$cache/render.lock"
  flock "$lock"
  size=$(screen_size)
  width=${size%x*}
  height=${size#*x}
  read -r left right top bottom < <(reserved_edges)
  visible_width=$((width - left - right))
  visible_height=$((height - top - bottom))
  if ((visible_width <= 0 || visible_height <= 0)); then
    echo "struts leave nothing of the ${size} screen: $left $right $top $bottom" >&2
    exit 1
  fi
  magick -size "$size" "xc:$background" \
    \( "${image}[0]" -auto-orient -resize "${visible_width}x${visible_height}^" \
       -gravity center -extent "${visible_width}x${visible_height}" \) \
    -gravity northwest -geometry "+${left}+${top}" -composite \
    -quality 95 "$cache/screen.part.jpg"
  mv "$cache/screen.part.jpg" "$cache/screen.jpg"
  feh --no-fehbg --bg-center "$cache/screen.jpg"
  exec {lock}>&-
}

# One page of the search, or nothing when Wallhaven can't be reached
search() {
  local query="$1" page="$2" size="$3"
  curl --silent --show-error --fail --max-time 30 --get "$api" \
    --data-urlencode "q=$query" \
    --data "categories=111" --data "purity=100" \
    --data "sorting=favorites" --data "order=desc" \
    --data "ratios=landscape" --data "atleast=$size" \
    --data "page=$page"
}

next() {
  local topic query size response last_page page history disliked candidate id url extension image
  topic=$(jq --raw-output 'keys[]' "$topics_file" | shuf --head-count=1)
  query=$(jq --raw-output --arg topic "$topic" '.[$topic][]' "$topics_file" | shuf --head-count=1)
  size=$(screen_size)

  # Being offline (or Wallhaven being down) is no error: the shown one stays
  if ! response=$(search "$query" 1 "$size"); then
    echo "Wallhaven is unreachable, the wallpaper stays" >&2
    return 0
  fi
  last_page=$(jq --exit-status '.meta.last_page' <<<"$response") || {
    echo "unexpected answer from Wallhaven for '$query': $response" >&2
    exit 1
  }
  if ((last_page == 0)); then
    echo "Wallhaven finds nothing for '$query' at $size; change the topic in wallpapers.nix" >&2
    exit 1
  fi
  page=$(shuf --input-range="1-$((last_page < top_pages ? last_page : top_pages))" --head-count=1)
  if ((page != 1)) && ! response=$(search "$query" "$page" "$size"); then
    echo "Wallhaven is unreachable, the wallpaper stays" >&2
    return 0
  fi

  # A random one not shown lately, or one shown lately if the whole page was;
  # never a disliked one
  history=$(ids_json "$cache/history")
  disliked=$(ids_json "$state/disliked")
  candidate=$(jq --compact-output --argjson history "$history" --argjson disliked "$disliked" '
      .data | map(select(.id | IN($disliked[]) | not))
      | (map(select(.id | IN($history[]) | not)) | select(. != [])) // .
      | .[]' <<<"$response" | shuf --head-count=1)
  if [[ -z $candidate ]]; then
    echo "nothing but disliked images on page $page for '$query', the wallpaper stays" >&2
    return 0
  fi
  id=$(jq --raw-output '.id' <<<"$candidate")
  url=$(jq --raw-output '.path' <<<"$candidate")
  extension="${url##*.}"
  image="$cache/wallhaven-$id.$extension"

  if ! curl --silent --show-error --fail --max-time 120 --output "$image.part" "$url"; then
    rm -f "$image.part"
    echo "can't download $url, the wallpaper stays" >&2
    return 0
  fi
  mv "$image.part" "$image"
  show "$image"
  echo "$topic ($query): https://wallhaven.cc/w/$id"

  echo "$id" >>"$cache/history"
  tail --lines="$remembered_ids" "$cache/history" >"$cache/history.new"
  mv "$cache/history.new" "$cache/history"
  # Oldest first out; the shown one is the newest
  find "$cache" -maxdepth 1 -name 'wallhaven-*' -printf '%T@ %p\n' | sort --numeric-sort --reverse \
    | tail --lines="+$((kept_images + 2))" | cut --delimiter=' ' --fields=2- | xargs --no-run-if-empty rm --
}

# A file of ids, one per line, as a JSON list
ids_json() {
  jq --raw-input --slurp 'split("\n") | map(select(. != ""))' "$1"
}

# The image shown now, or nothing if none was shown yet
current_image() {
  readlink --canonicalize-existing "$cache/current" || true
}

like() {
  local image
  image=$(current_image)
  if [[ -z $image ]]; then
    notify-send "Обои не сохранены" "Ещё ни одни не показаны"
    exit 1
  fi
  mkdir -p "$saved"
  cp "$image" "$saved/"
  notify-send "Обои сохранены" "$saved/$(basename "$image")"
}

dislike() {
  local image id
  image=$(current_image)
  if [[ -n $image ]]; then
    id=$(basename "$image")
    id=${id#wallhaven-}
    echo "${id%.*}" >>"$state/disliked"
  fi
  # Through the service, so that it never runs alongside the timer's pick; it
  # also postpones the timer's next one
  systemctl --user start wallpaper.service
}

refresh() {
  local image
  image=$(current_image)
  # Nothing shown yet: nothing to fit
  [[ -z $image ]] || render "$image"
}

restore() {
  if [[ -n $(current_image) ]]; then
    refresh
  else
    next
  fi
}

case "${1:-}" in
  next) next ;;
  like) like ;;
  dislike) dislike ;;
  refresh) refresh ;;
  restore) restore ;;
  *)
    echo "usage: wallpaper next|like|dislike|refresh|restore" >&2
    exit 2
    ;;
esac
