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

# Query monitors JSON from hyprctl
monitors_json=$(hyprctl monitors -j 2>/dev/null) || {
    echo "[ERR] Cannot toggle refresh rate: failed to query hyprctl monitors." >&2
    notify-send -u critical -a "Display" "Refresh Rate Toggle Failed" "Failed to query monitors from hyprctl" -i dialog-error 2>/dev/null || true
    exit 1
}

# Extract output name and refresh rate from the same monitor record
MONITOR=""
CURRENT_HZ_RAW=""
parsed=$(echo "$monitors_json" | jq -r '
    if (type == "array" and length > 0 and (.[0] | type == "object") and .[0].name != null and .[0].refreshRate != null and .[0].name != "" and (.[0].refreshRate | tostring) != "") then
        .[0].name,
        (.[0].refreshRate | tostring)
    else
        empty
    end
' 2>/dev/null || true)

if [ -n "$parsed" ]; then
    {
        read -r MONITOR || true
        read -r CURRENT_HZ_RAW || true
    } <<< "$parsed"
fi

# Fail and stop if no record exists or either value is missing (do not substitute defaults)
if [ -z "$MONITOR" ] || [ -z "$CURRENT_HZ_RAW" ]; then
    echo "[ERR] Cannot toggle refresh rate: no monitor record found or missing name/refreshRate." >&2
    notify-send -u critical -a "Display" "Refresh Rate Toggle Failed" "No active monitor record found or missing name/refreshRate" -i dialog-error 2>/dev/null || true
    exit 1
fi

CURRENT_HZ="${CURRENT_HZ_RAW%%.*}"
if ! [[ "$CURRENT_HZ" =~ ^[0-9]+$ ]]; then
    echo "[ERR] Cannot toggle refresh rate: invalid refresh rate value '$CURRENT_HZ_RAW'." >&2
    notify-send -u critical -a "Display" "Refresh Rate Toggle Failed" "Invalid refresh rate '$CURRENT_HZ_RAW'" -i dialog-error 2>/dev/null || true
    exit 1
fi

if [ "$CURRENT_HZ" -ge 100 ]; then
    # Switch to 60Hz via Lua evaluation
    hyprctl eval "hl.monitor({ output = '$MONITOR', mode = '1920x1080@60', position = '0x0', scale = '1' })"
    notify-send -a "Display" "Refresh Rate" "Switched to 60 Hz (Power Saving)" -i video-display
else
    # Switch to 144Hz via Lua evaluation
    hyprctl eval "hl.monitor({ output = '$MONITOR', mode = '1920x1080@144.002', position = '0x0', scale = '1' })"
    notify-send -a "Display" "Refresh Rate" "Switched to 144 Hz (Smooth)" -i video-display
fi
