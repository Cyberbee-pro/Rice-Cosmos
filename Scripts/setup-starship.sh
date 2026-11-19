#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Standalone Starship Prompt Setup
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

STARSHIP_SRC="${REPO_ROOT}/configs/starship"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/starship"
TARGET_TOML="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"

echo -e "${CYAN}[..] Configuring Standalone Starship Prompt . . . .${NC}"

if [ ! -d "$STARSHIP_SRC" ]; then
    echo -e "${RED}[ERR] Starship source configuration not found: ${STARSHIP_SRC}${NC}"
    exit 1
fi

# 1. Ensure starship is installed via pacman
if ! command -v starship &>/dev/null; then
    echo -e "${YELLOW}[..] starship is missing. Installing via pacman...${NC}"
    if [ "$EUID" -eq 0 ]; then
        pacman -S --needed --noconfirm starship
    elif command -v sudo &>/dev/null; then
        sudo pacman -S --needed --noconfirm starship
    else
        echo -e "${RED}[ERR] Root privileges or sudo required to install starship.${NC}"
        exit 1
    fi
fi

# 2. Non-destructively back up existing ~/.config/starship
if [ -L "$TARGET_DIR" ] || { [ -d "$TARGET_DIR" ] && [ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; }; then
    backup_path="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)"
    count=1
    while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
        backup_path="${TARGET_DIR}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
        count=$((count + 1))
    done
    echo -e "${YELLOW}[..] Backing up existing Starship directory to: ${backup_path}${NC}"
    if [ -L "$TARGET_DIR" ] && [ ! -e "$TARGET_DIR" ]; then
        cp -P "$TARGET_DIR" "$backup_path"
    else
        cp -r "$TARGET_DIR" "$backup_path"
    fi
fi

if [ -L "$TARGET_DIR" ]; then
    rm -f "$TARGET_DIR"
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
    cp -L "$TARGET_TOML" "$backup_toml"
    rm -f "$TARGET_TOML"
fi

mkdir -p "$TARGET_DIR"

# 4. Deploy configs/starship/. in-place to ~/.config/starship/
echo -e "${CYAN}[..] Deploying Starship configuration to ${TARGET_DIR}...${NC}"
if cp -rf "$STARSHIP_SRC/." "$TARGET_DIR/"; then
    chmod -R u+w "$TARGET_DIR" 2>/dev/null || true
    echo -e "${GREEN}[OK] Starship configuration deployed to ${TARGET_DIR}.${NC}"
else
    echo -e "${RED}[ERR] Failed to copy Starship configuration.${NC}"
    exit 1
fi

# 5. Also copy starship.toml to ~/.config/starship.toml (standard XDG path)
if [ -f "$TARGET_DIR/starship.toml" ]; then
    cp -f "$TARGET_DIR/starship.toml" "$TARGET_TOML"
    chmod u+w "$TARGET_TOML" 2>/dev/null || true
    echo -e "${GREEN}[OK] Deployed ${TARGET_TOML}.${NC}"
fi
