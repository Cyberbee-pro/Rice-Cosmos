#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Multi-App Dotfile Deployer (Repo -> System)
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

CONFIGS_DIR="${REPO_ROOT}/configs"
TARGET_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

echo -e "${CYAN}[..] Deploying Configurations to ${TARGET_CONFIG_DIR} . . . .${NC}"

if [ ! -d "$CONFIGS_DIR" ]; then
    echo -e "${RED}[ERR] Configurations folder not found: ${CONFIGS_DIR}${NC}"
    exit 1
fi

# Iterate through every app directory in ./configs/ (e.g. hypr, kitty, fastfetch, starship)
for app_path in "$CONFIGS_DIR"/*; do
    [ -d "$app_path" ] || continue
    app="$(basename "$app_path")"
    target_app_dir="${TARGET_CONFIG_DIR}/${app}"

    echo -e "${CYAN}[..] Deploying ${app} configuration to ${target_app_dir}...${NC}"

    # Create timestamped collision-resistant backup if non-empty directory or symlink exists
    if [ -L "$target_app_dir" ] || { [ -d "$target_app_dir" ] && [ -n "$(ls -A "$target_app_dir" 2>/dev/null)" ]; }; then
        backup_path="${target_app_dir}.backup_$(date +%Y%m%d_%H%M%S)"
        count=1
        while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
            backup_path="${target_app_dir}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
            count=$((count + 1))
        done
        echo -e "${YELLOW}[..] Backing up existing ${app} config to: ${backup_path}${NC}"
        if [ -L "$target_app_dir" ] && [ ! -e "$target_app_dir" ]; then
            cp -P "$target_app_dir" "$backup_path"
        else
            cp -rL "$target_app_dir" "$backup_path"
        fi
    fi

    # If ~/.config/<app> is a symlink (e.g. Nix store / Home Manager), remove the symlink before copying
    if [ -L "$target_app_dir" ]; then
        rm -f "$target_app_dir"
    fi

    mkdir -p "$target_app_dir"

    # Copy files cleanly
    if cp -r --remove-destination "$app_path"/. "$target_app_dir"/; then
        chmod -R u+w "$target_app_dir" 2>/dev/null || true
        echo -e "${GREEN}[OK] ${app} configurations deployed successfully to ${target_app_dir}.${NC}"
    else
        echo -e "${RED}[ERR] Failed to copy ${app} configuration files.${NC}"
        exit 1
    fi
done

# Remove any stale ~/.config/hypr/hyprland-gui.lua upon deployment so unified hyprland.lua runs cleanly
if [ -f "${TARGET_CONFIG_DIR}/hypr/hyprland-gui.lua" ] || [ -L "${TARGET_CONFIG_DIR}/hypr/hyprland-gui.lua" ]; then
    rm -f "${TARGET_CONFIG_DIR}/hypr/hyprland-gui.lua"
    echo -e "${GREEN}[OK] Removed stale ${TARGET_CONFIG_DIR}/hypr/hyprland-gui.lua.${NC}"
fi

# Also copy ~/.config/starship/starship.toml to ~/.config/starship.toml so Starship loads it automatically
starship_src="${TARGET_CONFIG_DIR}/starship/starship.toml"
starship_dest="${TARGET_CONFIG_DIR}/starship.toml"
if [ -f "$starship_src" ]; then
    if [ -L "$starship_dest" ]; then
        rm -f "$starship_dest"
    fi
    if cp --remove-destination "$starship_src" "$starship_dest"; then
        chmod u+w "$starship_dest" 2>/dev/null || true
        echo -e "${GREEN}[OK] Starship configuration copied to ${starship_dest}.${NC}"
    else
        echo -e "${YELLOW}[!] Warning: Failed to copy starship.toml to ${starship_dest}.${NC}"
    fi
fi
