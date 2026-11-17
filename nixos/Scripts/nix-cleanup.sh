#!/usr/bin/env bash
# cybees-clean.sh - System maintenance, space reclamation, and progress tracking

# 1. Capture initial disk usage of the root partition (in KB)
USED_BEFORE=$(df -k / | awk 'NR==2 {print $3}')
TOTAL_STEPS=5
CURRENT_STEP=0
WARNINGS=0

# 2. Function to draw the progress bar
draw_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local filled=$((CURRENT_STEP * 40 / TOTAL_STEPS))
    local empty=$((40 - filled))
    
    echo -e "\n\033[1;36m[$(printf "%${filled}s" | tr ' ' '#')$(printf "%${empty}s" | tr ' ' '-')] ${percent}%\033[0m"
    echo -e "\033[1;33mStep $CURRENT_STEP/$TOTAL_STEPS: $1\033[0m"
}

echo -e "\n\033[1;36mStarting System Deep Clean...\033[0m"

# Step 1
draw_progress "Vacuuming systemd journal logs"
if sudo journalctl --vacuum-time=3d; then
    echo "Journal logs vacuumed."
else
    echo -e "\033[1;33m[!] Warning: Failed to vacuum journalctl logs.\033[0m"
    WARNINGS=$((WARNINGS + 1))
fi

# Step 2
draw_progress "Pruning Podman container artifacts"
if command -v podman &>/dev/null; then
    if podman system prune -af; then
        echo "Podman artifacts pruned."
    else
        echo -e "\033[1;33m[!] Warning: Podman system prune encountered errors.\033[0m"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "Podman not found in PATH, skipping prune."
fi

# Step 3
draw_progress "Clearing user caches"
rm -rf ~/.cache/thumbnails/* 2>/dev/null || true
rm -rf ~/.npm/_cacache 2>/dev/null || true
rm -rf ~/.cache/bun/* 2>/dev/null || true
echo "Caches cleared."

# Step 4
draw_progress "Executing Selective Nix Garbage Collection"
prune_generations() {
    local profile="$1"
    local cmd_prefix="$2"
    local -a gens=()
    mapfile -t gens < <($cmd_prefix nix-env --list-generations -p "$profile" 2>/dev/null | awk '{print $1}')
    local total=${#gens[@]}

    if [ "$total" -gt 4 ]; then
        local -a to_delete=("${gens[@]:2:$((total-4))}")
        echo "Found $total generations for $profile."
        echo "Preserving first 2 and last 2. Removing: ${to_delete[*]}"
        if ! $cmd_prefix nix-env -p "$profile" --delete-generations "${to_delete[@]}"; then
            echo -e "\033[1;33m[!] Warning: Failed to delete generations for $profile.\033[0m"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo "Found $total generations for $profile (4 or fewer, skipping prune)."
    fi
}

# Execute prune logic for both system and user profiles
prune_generations "/nix/var/nix/profiles/system" "sudo"
if [ -e "/nix/var/nix/profiles/per-user/$USER/profile" ]; then
    prune_generations "/nix/var/nix/profiles/per-user/$USER/profile" ""
fi

# Clear unreferenced store paths (without --delete-older-than to preserve kept generations)
if ! sudo nix-collect-garbage; then
    echo -e "\033[1;33m[!] Warning: nix-collect-garbage encountered errors.\033[0m"
    WARNINGS=$((WARNINGS + 1))
fi

# Step 5
draw_progress "Optimizing the Nix Store (This may take a while)"
if ! nix-store --optimize; then
    echo -e "\033[1;33m[!] Warning: nix-store --optimize encountered errors.\033[0m"
    WARNINGS=$((WARNINGS + 1))
fi

# 3. Calculate the difference in disk usage
USED_AFTER=$(df -k / | awk 'NR==2 {print $3}')
SAVED_KB=$((USED_BEFORE - USED_AFTER))

# Failsafe in case a background process actually increased disk usage during cleanup
if [ "$SAVED_KB" -lt 0 ]; then
    SAVED_KB=0
fi

# Convert KB to Megabytes or Gigabytes cleanly
SAVED_HUMAN=$(awk -v kb="$SAVED_KB" 'BEGIN {
    if (kb >= 1048576) printf "%.2f GB", kb/1048576
    else if (kb >= 1024) printf "%.2f MB", kb/1024
    else printf "%d KB", kb
}')

# 4. Final Output
echo -e "\n\033[1;34m========================================\033[0m"
if [ "$WARNINGS" -eq 0 ]; then
    echo -e "\033[1;32mCleanup Complete! All tasks finished successfully.\033[0m"
else
    echo -e "\033[1;33mCleanup Completed with $WARNINGS warning(s)/failure(s).\033[0m"
fi
echo -e "\033[1;36mTotal Disk Space Reclaimed: $SAVED_HUMAN\033[0m"
echo -e "\033[1;34m========================================\033[0m\n"
