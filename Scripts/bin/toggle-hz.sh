#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Display Refresh Rate Toggle (60Hz <-> 144Hz via Caelestia Lua)
# ==============================================================================

set -euo pipefail

# Require dependencies
if ! command -v jq &>/dev/null; then
    echo "[ERR] 'jq' is required by toggle-hz.sh but is not installed." >&2
    exit 1
fi

if ! command -v notify-send &>/dev/null; then
    echo "[ERR] 'notify-send' (libnotify) is required by toggle-hz.sh but is not installed." >&2
    exit 1
fi

if ! command -v hyprctl &>/dev/null; then
    echo "[ERR] 'hyprctl' is not available." >&2
    exit 1
fi

# Query active display name and refresh rate
MONITOR=$(hyprctl monitors -j | jq -r '.[0].name // "eDP-1"')
if [ -z "$MONITOR" ] || [ "$MONITOR" = "null" ]; then
    MONITOR="eDP-1"
fi

CURRENT_HZ=$(hyprctl monitors -j | jq -r '.[0].refreshRate // 60' | cut -d'.' -f1)

if [ "$CURRENT_HZ" -ge 100 ]; then
    # Switch to 60Hz via Lua evaluation
    hyprctl eval "hl.monitor({ output = '$MONITOR', mode = '1920x1080@60', position = '0x0', scale = '1' })"
    notify-send -a "Display" "Refresh Rate" "Switched to 60 Hz (Power Saving)" -i video-display
else
    # Switch to 144Hz via Lua evaluation
    hyprctl eval "hl.monitor({ output = '$MONITOR', mode = '1920x1080@144.002', position = '0x0', scale = '1' })"
    notify-send -a "Display" "Refresh Rate" "Switched to 144 Hz (Smooth)" -i video-display
fi
