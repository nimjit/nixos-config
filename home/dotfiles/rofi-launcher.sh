#!/usr/bin/env bash
# rofi-launcher — combi launcher with Ctrl+Return → quickanswer
#
# Normal usage: type app name, press Enter → app launches
# Search:       type query, press Ctrl+Return → quickanswer opens with query pre-loaded

query=$(rofi \
    -show combi \
    -kb-custom-1 "ctrl+Return" \
    -kb-accept-custom "" \
    -format f)

[ $? -eq 10 ] && [ -n "$query" ] && \
    /home/thijmen/.local/bin/rofi-quickanswer "$query" &
