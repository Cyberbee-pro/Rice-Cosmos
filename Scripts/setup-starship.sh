#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Standalone Starship Prompt Setup
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

STARSHIP_SRC="${REPO_ROOT}/configs/starship"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/starship"
TARGET_TOML="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"

echo -e "${CYAN}[..] Configuring Standalone Starship Prompt (${DISTRO^^}) . . . .${NC}"

if [ ! -d "$STARSHIP_SRC" ]; then
    echo -e "${RED}[ERR] Starship source configuration not found: ${STARSHIP_SRC}${NC}"
    exit 1
fi

# 1. Ensure starship is installed
if ! command -v starship &>/dev/null; then
    if [ "$DISTRO" = "arch" ]; then
        echo -e "${YELLOW}[..] starship is missing. Installing via pacman...${NC}"
        if command -v sudo &>/dev/null; then
            sudo pacman -S --needed --noconfirm starship
        else
            echo -e "${RED}[ERR] sudo required to install starship.${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}[!] NixOS manages packages declaratively. Please add 'pkgs.starship' or 'programs.starship.enable = true' to your configuration.nix.${NC}"
    fi
fi

# 2. Non-destructively back up existing ~/.config/starship via move
if [ -e "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; then
    if [ -L "$TARGET_DIR" ] || [ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; then
        backup_path="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)"
        count=1
        while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
            backup_path="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
            count=$((count + 1))
        done
        echo -e "${YELLOW}[..] Backing up existing Starship directory to: ${backup_path}${NC}"
        mv "$TARGET_DIR" "$backup_path"
    else
        rm -rf "$TARGET_DIR"
    fi
fi

# 3. Non-destructively back up existing ~/.config/starship.toml
if [ -e "$TARGET_TOML" ] || [ -L "$TARGET_TOML" ]; then
    backup_toml="${TARGET_TOML}.backup_$(date +%Y%m%d_%H%M%S)"
    count=1
    while [ -e "$backup_toml" ] || [ -L "$backup_toml" ]; do
        backup_toml="${TARGET_TOML}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
        count=$((count + 1))
    done
    echo -e "${YELLOW}[..] Backing up existing starship.toml to: ${backup_toml}${NC}"
    cp -P "$TARGET_TOML" "$backup_toml"
    rm -f "$TARGET_TOML"
fi

mkdir -p "$TARGET_DIR"

# 4. Deploy configs/starship/. into fresh directory
echo -e "${CYAN}[..] Deploying Starship configuration to ${TARGET_DIR}...${NC}"
if cp -r "$STARSHIP_SRC/." "$TARGET_DIR/"; then
    chmod -R u+w "$TARGET_DIR" 2>/dev/null || true
    echo -e "${GREEN}[OK] Starship configuration deployed to ${TARGET_DIR}.${NC}"
else
    echo -e "${RED}[ERR] Failed to copy Starship configuration.${NC}"
    exit 1
fi

# 5. Also deploy starship.toml to ~/.config/starship.toml (standard XDG path) via temp file + mv -f
tmp_toml=""
cleanup_tmp() {
    if [ -n "$tmp_toml" ] && [ -f "$tmp_toml" ]; then
        rm -f "$tmp_toml"
    fi
}
trap cleanup_tmp EXIT INT TERM

if [ -f "$TARGET_DIR/starship.toml" ]; then
    tmp_toml="$(mktemp "${TARGET_TOML}.tmp.XXXXXX")"
    cp -f "$TARGET_DIR/starship.toml" "$tmp_toml"
    chmod 0644 "$tmp_toml"
    mv -f "$tmp_toml" "$TARGET_TOML"
    echo -e "${GREEN}[OK] Deployed ${TARGET_TOML}.${NC}"
fi

trap - EXIT INT TERM
