#!/usr/bin/env bash
set -euo pipefail

if ! lpass status -q 2>/dev/null; then
    notify-send "LastPass" "Not logged in. Run: lpass login" --expire-time=4000
    exit 1
fi

entries=$(lpass ls 2>/dev/null) || exit 1
# Strip [id: ...], then strip the (none)/ group prefix for ungrouped entries
display=$(echo "$entries" | sed 's/ \[id:[^]]*\]//' | sed 's|^(none)/||')

selected=$(echo "$display" | rofi -dmenu -p " Password:" -i -format 'i' -no-custom)
[ -z "$selected" ] && exit 0

id=$(echo "$entries" | sed -n "$((selected+1))p" | grep -oP '\[id: \K[0-9]+')
name=$(echo "$display" | sed -n "$((selected+1))p")
lpass show --clip "$id" && notify-send "LastPass" "Copied: $name" --expire-time=3000
