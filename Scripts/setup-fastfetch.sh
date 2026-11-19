#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Standalone Fastfetch Setup
# ==============================================================================

set -euo pipefail

# Reject root/sudo invocation
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    echo -e "\033[0;31m[ERR] Please do not run this script as root or with sudo.\033[0m" >&2
    echo -e "\033[0;33m[!] Run as your regular desktop user. Elevation (sudo) will be prompted automatically if packages need to be installed.\033[0m" >&2
    exit 1
fi

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

FASTFETCH_SRC="${REPO_ROOT}/configs/fastfetch"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch"

echo -e "${CYAN}[..] Configuring Standalone Fastfetch . . . .${NC}"

if [ ! -d "$FASTFETCH_SRC" ]; then
    echo -e "${RED}[ERR] Fastfetch source configuration not found: ${FASTFETCH_SRC}${NC}"
    exit 1
fi

# 1. Ensure fastfetch is installed via pacman
if ! command -v fastfetch &>/dev/null; then
    echo -e "${YELLOW}[..] fastfetch is missing. Installing via pacman...${NC}"
    if command -v sudo &>/dev/null; then
        sudo pacman -S --needed --noconfirm fastfetch
    else
        echo -e "${RED}[ERR] sudo required to install fastfetch.${NC}"
        exit 1
    fi
fi

# 2. Non-destructively back up existing ~/.config/fastfetch via move
if [ -e "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; then
    if [ -L "$TARGET_DIR" ] || [ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; then
        backup_path="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)"
        count=1
        while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
            backup_path="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
            count=$((count + 1))
        done
        echo -e "${YELLOW}[..] Backing up existing Fastfetch configuration to: ${backup_path}${NC}"
        mv "$TARGET_DIR" "$backup_path"
    else
        rm -rf "$TARGET_DIR"
    fi
fi

mkdir -p "$TARGET_DIR"

# 3. Deploy configs/fastfetch/. into fresh directory
echo -e "${CYAN}[..] Deploying Fastfetch configuration to ${TARGET_DIR}...${NC}"
if cp -r "$FASTFETCH_SRC/." "$TARGET_DIR/"; then
    chmod -R u+w "$TARGET_DIR" 2>/dev/null || true
    echo -e "${GREEN}[OK] Fastfetch configuration deployed successfully to ${TARGET_DIR}.${NC}"
else
    echo -e "${RED}[ERR] Failed to copy Fastfetch configuration.${NC}"
    exit 1
fi
