#!/usr/bin/env bash

# Query active display name and refresh rate
MONITOR=$(hyprctl monitors -j | jq -r '.[0].name // "eDP-1"')
CURRENT_HZ=$(hyprctl monitors -j | jq -r '.[0].refreshRate' | cut -d'.' -f1)

if [ "$CURRENT_HZ" -ge 100 ]; then
    # Switch to 60Hz via Lua evaluation
    hyprctl eval "hl.monitor({ output = '$MONITOR', mode = '1920x1080@60', position = '0x0', scale = '1' })"
    notify-send -a "Display" "Refresh Rate" "Switched to 60 Hz (Power Saving)" -i video-display
else
    # Switch to 144Hz via Lua evaluation
    hyprctl eval "hl.monitor({ output = '$MONITOR', mode = '1920x1080@144.002', position = '0x0', scale = '1' })"
    notify-send -a "Display" "Refresh Rate" "Switched to 144 Hz (Smooth)" -i video-display
fi
