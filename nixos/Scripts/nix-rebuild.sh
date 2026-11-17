#!/usr/bin/env bash
# cybees-rebuild.sh - NixOS flake deployment and progress tracking

TOTAL_STEPS=3
CURRENT_STEP=0

# 1. Start execution timer
START_TIME=$(date +%s)

# 2. Progress bar function (matches your cleanup script)
draw_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local filled=$((CURRENT_STEP * 40 / TOTAL_STEPS))
    local empty=$((40 - filled))
    
    echo -e "\n\033[1;36m[$(printf "%${filled}s" | tr ' ' '#')$(printf "%${empty}s" | tr ' ' '-')] ${percent}%\033[0m"
    echo -e "\033[1;33mStep $CURRENT_STEP/$TOTAL_STEPS: $1\033[0m"
}

echo -e "\n\033[1;36mStarting NixOS System Rebuild...\033[0m"

# Step 1
draw_progress "Navigating to NixOS config directory"
if ! cd /etc/nixos; then
    echo -e "\n\033[1;31mError: /etc/nixos directory not found or inaccessible!\033[0m"
    exit 1
fi

# Step 2
draw_progress "Staging configuration changes for Flake visibility"
# Flakes cannot see untracked files. 'git add .' ensures any newly created modules are included.
git add .
# Briefly show what files were modified/staged before the build output starts
git status -s

# Step 3
draw_progress "Executing NixOS Rebuild (Switching to cybees-nix)"
echo -e "\033[1;30m(This may take a few minutes depending on compilation...)\033[0m\n"

# Execute the rebuild and catch whether it succeeds or fails
if sudo nixos-rebuild switch --flake /etc/nixos#cybees-nix; then
    BUILD_STATUS="\033[1;32mRebuild Successful! System updated.\033[0m"
else
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