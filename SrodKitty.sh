#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Kitty Dotfile Deployer
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KITTY_SRC="${SCRIPT_DIR}/configs/kitty"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"

echo -e "${CYAN}[..] Deploying Kitty Terminal Configurations . . . .${NC}"

if [ ! -d "$KITTY_SRC" ]; then
    echo -e "${RED}[ERR] Source folder not found: ${KITTY_SRC}${NC}"
    exit 1
fi

# Create timestamped backup if existing config directory or symlink is present
if [ -e "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; then
    BACKUP_PATH="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)"
    count=1
    while [ -e "$BACKUP_PATH" ] || [ -L "$BACKUP_PATH" ]; do
        BACKUP_PATH="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
        count=$((count + 1))
    done
    echo -e "${YELLOW}[..] Backing up existing Kitty config to: ${BACKUP_PATH}${NC}"
    if [ -L "$TARGET_DIR" ] && [ ! -e "$TARGET_DIR" ]; then
        cp -P "$TARGET_DIR" "$BACKUP_PATH"
    else
        cp -rL "$TARGET_DIR" "$BACKUP_PATH"
    fi
fi

# Remove symlink itself if pointing to read-only Nix store
if [ -L "$TARGET_DIR" ]; then
    rm -f "$TARGET_DIR"
fi

mkdir -p "$TARGET_DIR"

# Copy all files including dotfiles cleanly
if cp -r --remove-destination "$KITTY_SRC"/. "$TARGET_DIR"/; then
    chmod -R u+w "$TARGET_DIR" 2>/dev/null || true
    echo -e "${GREEN}[OK] Kitty configurations deployed successfully to ${TARGET_DIR}.${NC}"
else
    echo -e "${RED}[ERR] Failed to copy Kitty configuration files.${NC}"
    exit 1
fi