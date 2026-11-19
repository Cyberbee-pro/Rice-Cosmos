#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Standalone Kitty Setup
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

detect_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        case "${ID:-}:${ID_LIKE:-}" in
            *nixos*|*nix*)
                echo "nixos"
                ;;
            *arch*|*endeavouros*|*manjaro*|*garuda*|*artix*)
                echo "arch"
                ;;
            *)
                if command -v pacman &>/dev/null; then echo "arch";
                elif command -v nix &>/dev/null; then echo "nixos";
                else echo "arch"; fi
                ;;
        esac
    else
        if command -v pacman &>/dev/null; then echo "arch";
        elif command -v nix &>/dev/null; then echo "nixos";
        else echo "arch"; fi
    fi
}

DISTRO="${DISTRO:-$(detect_distro)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/configs" ]; then
    REPO_ROOT="$SCRIPT_DIR"
elif [ -d "$SCRIPT_DIR/../configs" ]; then
    REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    REPO_ROOT="$SCRIPT_DIR"
fi

KITTY_SRC="${REPO_ROOT}/configs/kitty"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"

echo -e "${CYAN}[..] Configuring Standalone Kitty Terminal (${DISTRO^^}) . . . .${NC}"

if [ ! -d "$KITTY_SRC" ]; then
    echo -e "${RED}[ERR] Kitty source configuration not found: ${KITTY_SRC}${NC}"
    exit 1
fi

# 1. Ensure kitty and nerd font are installed
if [ "$DISTRO" = "arch" ]; then
    missing_pkgs=()
    if ! command -v kitty &>/dev/null; then
        missing_pkgs+=("kitty")
    fi
    if ! pacman -Q ttf-jetbrains-mono-nerd &>/dev/null; then
        missing_pkgs+=("ttf-jetbrains-mono-nerd")
    fi

    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        echo -e "${YELLOW}[..] Installing missing packages via pacman: ${missing_pkgs[*]}...${NC}"
        if command -v sudo &>/dev/null; then
            sudo pacman -S --needed --noconfirm "${missing_pkgs[@]}"
        else
            echo -e "${RED}[ERR] sudo required to install: ${missing_pkgs[*]}${NC}"
            exit 1
        fi
    fi
else
    if ! command -v kitty &>/dev/null; then
        echo -e "${YELLOW}[!] NixOS manages packages declaratively. Please add 'pkgs.kitty' and Nerd Fonts to your configuration.nix.${NC}"
    fi
fi

# 2. Non-destructively back up existing ~/.config/kitty via move
if [ -e "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; then
    if [ -L "$TARGET_DIR" ] || [ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; then
        backup_path="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)"
        count=1
        while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
            backup_path="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
            count=$((count + 1))
        done
        echo -e "${YELLOW}[..] Backing up existing Kitty configuration to: ${backup_path}${NC}"
        mv "$TARGET_DIR" "$backup_path"
    else
        rm -rf "$TARGET_DIR"
    fi
fi

mkdir -p "$TARGET_DIR"

# 3. Deploy configs/kitty/. into fresh directory
echo -e "${CYAN}[..] Deploying Kitty configuration to ${TARGET_DIR}...${NC}"
if cp -r "$KITTY_SRC/." "$TARGET_DIR/"; then
    chmod -R u+w "$TARGET_DIR" 2>/dev/null || true
    echo -e "${GREEN}[OK] Kitty configuration deployed successfully to ${TARGET_DIR}.${NC}"
else
    echo -e "${RED}[ERR] Failed to copy Kitty configuration.${NC}"
    exit 1
fi
