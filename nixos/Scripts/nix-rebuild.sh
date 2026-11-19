#!/usr/bin/env bash
# nix-rebuild.sh - NixOS flake deployment and progress tracking

set -euo pipefail

TOTAL_STEPS=3
CURRENT_STEP=0

# 1. Start execution timer
START_TIME=$(date +%s)

# 2. Progress bar function
draw_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local filled=$((CURRENT_STEP * 40 / TOTAL_STEPS))
    local empty=$((40 - filled))

    echo -e "\n\033[1;36m[$(printf "%${filled}s" | tr ' ' '#')$(printf "%${empty}s" | tr ' ' '-')] ${percent}%\033[0m"
    echo -e "\033[1;33mStep $CURRENT_STEP/$TOTAL_STEPS: $1\033[0m"
}

# Resolve target host configuration (defaults to rice-cosmos or system hostname)
TARGET_HOST="${1:-}"
if [ -z "$TARGET_HOST" ]; then
    current_host="$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "rice-cosmos")"
    if [ "$current_host" = "rice-cosmos" ] || [ ! -f /etc/nixos/flake.nix ]; then
        TARGET_HOST="rice-cosmos"
    elif grep -q "nixosConfigurations\.${current_host}" /etc/nixos/flake.nix 2>/dev/null; then
        TARGET_HOST="$current_host"
    else
        TARGET_HOST="rice-cosmos"
    fi
fi

echo -e "\n\033[1;36mStarting NixOS System Rebuild (${TARGET_HOST})...\033[0m"

# Step 1
draw_progress "Navigating to NixOS config directory"
if ! cd /etc/nixos; then
    echo -e "\n\033[1;31mError: /etc/nixos directory not found or inaccessible!\033[0m"
    exit 1
fi

# Step 2
draw_progress "Staging configuration changes for Flake visibility"
target_paths=()
for path in flake.nix flake.lock configuration.nix hardware-configuration.nix Scripts .gitignore; do
    if [ -e "$path" ]; then
        target_paths+=("$path")
    fi
done

if [ ${#target_paths[@]} -gt 0 ]; then
    if [ -d .git ] || git rev-parse --is-inside-work-tree &>/dev/null; then
        git add -- "${target_paths[@]}" 2>/dev/null || true
        git status -s
    fi
fi

# Step 3
draw_progress "Executing NixOS Rebuild (Switching to ${TARGET_HOST})"
echo -e "\033[1;30m(This may take a few minutes depending on compilation...)\033[0m\n"

# Execute the rebuild and capture the exact exit status
if sudo nixos-rebuild switch --flake "/etc/nixos#${TARGET_HOST}"; then
    REBUILD_EXIT=0
    BUILD_STATUS="\033[1;32mRebuild Successful! System updated.\033[0m"
else
    REBUILD_EXIT=$?
    BUILD_STATUS="\033[1;31mRebuild Failed! Check the Nix logs above for syntax errors.\033[0m"
fi

# 3. Stop timer and calculate elapsed time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINS=$((ELAPSED / 60))
SECS=$((ELAPSED % 60))

# 4. Final Output
echo -e "\n\033[1;34m========================================\033[0m"
echo -e "$BUILD_STATUS"
echo -e "\033[1;36mBuild Time: ${MINS}m ${SECS}s\033[0m"
echo -e "\033[1;34m========================================\033[0m\n"

exit "$REBUILD_EXIT"
