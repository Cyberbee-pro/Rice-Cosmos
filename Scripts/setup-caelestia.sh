#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Standalone Caelestia Shell Setup
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

CAELESTIA_SRC="${REPO_ROOT}/configs/caelestia"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia"

echo -e "${CYAN}[..] Configuring Standalone Caelestia Shell . . . .${NC}"

if [ ! -d "$CAELESTIA_SRC" ]; then
    echo -e "${RED}[ERR] Caelestia source configuration not found: ${CAELESTIA_SRC}${NC}"
    exit 1
fi

# 1. Determine user runner for AUR operations (makepkg/paru/yay MUST NOT run as root)
if [ "$EUID" -eq 0 ]; then
    if [ -z "${SUDO_USER:-}" ] || [ "${SUDO_USER}" = "root" ]; then
        echo -e "${RED}[ERR] AUR helpers cannot run as root, and no non-root SUDO_USER was found.${NC}"
        exit 1
    fi
    run_as_user() { sudo -u "$SUDO_USER" "$@"; }
else
    run_as_user() { "$@"; }
fi

# 2. Check and install Caelestia Shell & CLI via paru or yay
need_shell=0
need_cli=0
if ! command -v caelestia &>/dev/null; then
    need_cli=1
fi
if ! pacman -Q caelestia-shell &>/dev/null; then
    need_shell=1
fi

if [ "$need_shell" -eq 1 ] || [ "$need_cli" -eq 1 ]; then
    echo -e "${CYAN}[..] Checking AUR helper for Caelestia packages...${NC}"
    AUR_HELPER=""
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    fi

    if [ -z "$AUR_HELPER" ]; then
        echo -e "${CYAN}[..] Neither paru nor yay found. Bootstrapping yay-bin . . . .${NC}"
        # Ensure base-devel and git are present
        if [ "$EUID" -eq 0 ]; then
            pacman -S --needed --noconfirm base-devel git
        elif command -v sudo &>/dev/null; then
            sudo pacman -S --needed --noconfirm base-devel git
        fi
        rm -rf /tmp/yay-bin
        run_as_user git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
        (
            cd /tmp/yay-bin
            run_as_user makepkg -si --noconfirm
        )
        AUR_HELPER="yay"
        echo -e "${GREEN}[OK] yay-bin bootstrapped successfully.${NC}"
    else
        echo -e "${GREEN}[OK] Detected existing AUR helper: ${AUR_HELPER}.${NC}"
    fi

    echo -e "${CYAN}[..] Installing caelestia-shell and caelestia-cli via ${AUR_HELPER}...${NC}"
    run_as_user "$AUR_HELPER" -S --needed --noconfirm caelestia-shell caelestia-cli
    echo -e "${GREEN}[OK] Caelestia Shell & CLI installation complete.${NC}"
fi

# 3. Non-destructively back up existing ~/.config/caelestia
if [ -L "$TARGET_DIR" ] || { [ -d "$TARGET_DIR" ] && [ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; }; then
    backup_path="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)"
    count=1
    while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
        backup_path="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
        count=$((count + 1))
    done
    echo -e "${YELLOW}[..] Backing up existing Caelestia configuration to: ${backup_path}${NC}"
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

# 4. Deploy configs/caelestia/. in-place
echo -e "${CYAN}[..] Deploying Caelestia configuration to ${TARGET_DIR}...${NC}"
if cp -rf "$CAELESTIA_SRC/." "$TARGET_DIR/"; then
    chmod -R u+w "$TARGET_DIR" 2>/dev/null || true
    echo -e "${GREEN}[OK] Caelestia configuration deployed successfully to ${TARGET_DIR}.${NC}"
else
    echo -e "${RED}[ERR] Failed to copy Caelestia configuration.${NC}"
    exit 1
fi

# 5. Remove or back up leftover monolithic ~/.config/hypr/hyprland.conf to prevent shadowing hyprland.lua
HYPR_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.conf"
if [ -e "$HYPR_CONF" ] || [ -L "$HYPR_CONF" ]; then
    backup_conf="${HYPR_CONF}.backup_$(date +%Y%m%d_%H%M%S)"
    count=1
    while [ -e "$backup_conf" ] || [ -L "$backup_conf" ]; do
        backup_conf="${HYPR_CONF}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
        count=$((count + 1))
    done
    echo -e "${YELLOW}[..] Backing up leftover monolithic ${HYPR_CONF} to: ${backup_conf}${NC}"
    cp -L "$HYPR_CONF" "$backup_conf"
    rm -f "$HYPR_CONF"
    echo -e "${GREEN}[OK] Removed leftover monolithic hyprland.conf so Caelestia's hyprland.lua is never shadowed.${NC}"
fi
