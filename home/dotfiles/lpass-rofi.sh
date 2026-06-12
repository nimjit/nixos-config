#!/usr/bin/env bash
set -euo pipefail

if ! lpass status -q 2>/dev/null; then
    notify-send "LastPass" "Not logged in. Run: lpass login thijmen.nouwens@gmail.com" --expire-time=4000
    exit 1
fi

entries=$(lpass ls --long 2>/dev/null) || exit 1
selected=$(echo "$entries" | rofi -dmenu -p " Password:" -i -format 'i' -no-custom)
[ -z "$selected" ] && exit 0

name=$(echo "$entries" | sed -n "$((selected+1))p" | sed 's/ \[id:.*\]//')
lpass show --clip "$name" && notify-send "LastPass" "Copied: $name" --expire-time=3000
