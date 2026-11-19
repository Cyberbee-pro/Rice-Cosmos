#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Standalone Neovim Setup
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/configs" ]; then
    REPO_ROOT="$SCRIPT_DIR"
elif [ -d "$SCRIPT_DIR/../configs" ]; then
    REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    REPO_ROOT="$SCRIPT_DIR"
fi

NVIM_SRC="${REPO_ROOT}/configs/nvim"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

echo -e "${CYAN}[..] Configuring Standalone Neovim . . . .${NC}"

if [ ! -d "$NVIM_SRC" ]; then
    echo -e "${RED}[ERR] Neovim source configuration not found: ${NVIM_SRC}${NC}"
    exit 1
fi

# 1. Ensure neovim is installed via pacman
if ! command -v nvim &>/dev/null; then
    echo -e "${YELLOW}[..] neovim is missing. Installing via pacman...${NC}"
    if [ "$EUID" -eq 0 ]; then
        pacman -S --needed --noconfirm neovim
    elif command -v sudo &>/dev/null; then
        sudo pacman -S --needed --noconfirm neovim
    else
        echo -e "${RED}[ERR] Root privileges or sudo required to install neovim.${NC}"
        exit 1
    fi
fi

# 2. Non-destructively back up existing ~/.config/nvim
if [ -L "$TARGET_DIR" ] || { [ -d "$TARGET_DIR" ] && [ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; }; then
    backup_path="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)"
    count=1
    while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
        backup_path="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
        count=$((count + 1))
    done
    echo -e "${YELLOW}[..] Backing up existing Neovim configuration to: ${backup_path}${NC}"
    if [ -L "$TARGET_DIR" ] && [ ! -e "$TARGET_DIR" ]; then
        cp -P "$TARGET_DIR" "$backup_path"
    else
        cp -r "$TARGET_DIR" "$backup_path"
    fi
fi

if [ -L "$TARGET_DIR" ]; then
    rm -f "$TARGET_DIR"
fi

mkdir -p "$TARGET_DIR"

# 3. Deploy configs/nvim/. in-place (excluding .git)
echo -e "${CYAN}[..] Deploying Neovim configuration to ${TARGET_DIR}...${NC}"
if cp -rf "$NVIM_SRC/." "$TARGET_DIR/"; then
    # Remove any cloned .git directory inside target config
    rm -rf "$TARGET_DIR/.git" 2>/dev/null || true
    chmod -R u+w "$TARGET_DIR" 2>/dev/null || true
    echo -e "${GREEN}[OK] Neovim configuration deployed successfully to ${TARGET_DIR}.${NC}"
else
    echo -e "${RED}[ERR] Failed to copy Neovim configuration.${NC}"
    exit 1
fi
