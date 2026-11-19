#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Standalone Hyprland Setup
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

HYPR_SRC="${REPO_ROOT}/configs/hypr"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"

echo -e "${CYAN}[..] Configuring Standalone Hyprland Environment . . . .${NC}"

if [ ! -d "$HYPR_SRC" ]; then
    echo -e "${RED}[ERR] Hyprland source configuration not found: ${HYPR_SRC}${NC}"
    exit 1
fi

# 1. Install required Hyprland ecosystem packages via pacman
HYPR_PKGS=(
    hyprland
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    polkit-gnome
    grim
    slurp
    wl-clipboard
    satty
    jq
    libnotify
)

missing_pkgs=()
for pkg in "${HYPR_PKGS[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        missing_pkgs+=("$pkg")
    fi
done

if [ ${#missing_pkgs[@]} -gt 0 ]; then
    echo -e "${YELLOW}[..] Installing missing packages via pacman: ${missing_pkgs[*]}...${NC}"
    if [ "$EUID" -eq 0 ]; then
        pacman -S --needed --noconfirm "${missing_pkgs[@]}"
    elif command -v sudo &>/dev/null; then
        sudo pacman -S --needed --noconfirm "${missing_pkgs[@]}"
    else
        echo -e "${RED}[ERR] Root privileges or sudo required to install: ${missing_pkgs[*]}${NC}"
        exit 1
    fi
fi

# 2. Non-destructively back up existing ~/.config/hypr
if [ -L "$TARGET_DIR" ] || { [ -d "$TARGET_DIR" ] && [ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; }; then
    backup_path="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)"
    count=1
    while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
        backup_path="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
        count=$((count + 1))
    done
    echo -e "${YELLOW}[..] Backing up existing Hyprland configuration to: ${backup_path}${NC}"
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

# 3. Deploy configs/hypr/. in-place
echo -e "${CYAN}[..] Deploying Hyprland configuration to ${TARGET_DIR}...${NC}"
if cp -rf "$HYPR_SRC/." "$TARGET_DIR/"; then
    chmod -R u+w "$TARGET_DIR" 2>/dev/null || true
    echo -e "${GREEN}[OK] Hyprland configuration deployed successfully to ${TARGET_DIR}.${NC}"
else
    echo -e "${RED}[ERR] Failed to copy Hyprland configuration.${NC}"
    exit 1
fi

# 4. Ensure executable permissions on helper scripts
if [ -d "$TARGET_DIR/scripts" ]; then
    chmod +x "$TARGET_DIR/scripts"/* 2>/dev/null || true
    echo -e "${GREEN}[OK] Ensured executable permissions on ${TARGET_DIR}/scripts/*.${NC}"
fi

# 5. Clean up stale hyprland-gui.lua and leftover monolithic hyprland.conf
if [ -e "$TARGET_DIR/hyprland-gui.lua" ] || [ -L "$TARGET_DIR/hyprland-gui.lua" ]; then
    rm -f "$TARGET_DIR/hyprland-gui.lua"
    echo -e "${GREEN}[OK] Removed legacy hyprland-gui.lua.${NC}"
fi

if [ -e "$TARGET_DIR/hyprland.conf" ] || [ -L "$TARGET_DIR/hyprland.conf" ]; then
    backup_conf="${TARGET_DIR}/hyprland.conf.backup_$(date +%Y%m%d_%H%M%S)"
    cp -L "$TARGET_DIR/hyprland.conf" "$backup_conf"
    rm -f "$TARGET_DIR/hyprland.conf"
    echo -e "${GREEN}[OK] Removed leftover monolithic hyprland.conf (backed up to ${backup_conf}).${NC}"
fi
