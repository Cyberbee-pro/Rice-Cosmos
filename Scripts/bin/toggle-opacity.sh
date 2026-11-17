#!/usr/bin/env bash
addr=$(hyprctl activewindow -j | jq -r '.address')
[ "$addr" = "null" ] && exit 0

state_file="/tmp/opacity_$addr"
if [ -f "$state_file" ]; then
    hyprctl setprop address "$addr" alpha 0.88
    rm "$state_file"
else
    hyprctl setprop address "$addr" alpha 1.0
    touch "$state_file"
fi
