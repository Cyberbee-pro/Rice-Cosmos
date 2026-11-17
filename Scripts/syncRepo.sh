#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Live Configuration Harvester (System -> Repo)
# ==============================================================================

set -euo pipefail

# ANSI Palette
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Resolve Repository Root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -d "$SCRIPT_DIR/configs" ]; then
    REPO_ROOT="$SCRIPT_DIR"
elif [ -d "$SCRIPT_DIR/../configs" ]; then
    REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    REPO_ROOT="$SCRIPT_DIR"
fi

REPO_CONFIGS="${REPO_ROOT}/configs"
SRC_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
REPO_BIN="${REPO_ROOT}/Scripts/bin"
SRC_BIN_DIR="${HOME}/.local/bin"

echo -e "${CYAN}[..] Harvesting live configurations from ${SRC_CONFIG_DIR} into ${REPO_CONFIGS} . . . .${NC}"

mkdir -p "$REPO_CONFIGS"

# 1. Harvest Standard App Directories
APPS=("hypr" "kitty" "fastfetch" "starship" "caelestia" "nvim")
for app in "${APPS[@]}"; do
    src_app_dir="${SRC_CONFIG_DIR}/${app}"
    dest_app_dir="${REPO_CONFIGS}/${app}"

    if [ -d "$src_app_dir" ] || [ -L "$src_app_dir" ]; then
        echo -e "${CYAN}[..] Harvesting ${app} from ${src_app_dir}...${NC}"
        mkdir -p "$dest_app_dir"
        # Dereference symlinks (cp -rL) to capture real contents instead of broken Nix store links
        if cp -rL --remove-destination "${src_app_dir}"/. "${dest_app_dir}"/; then
            chmod -R u+w "${dest_app_dir}" 2>/dev/null || true
            echo -e "${GREEN}[OK] Harvested ${app} configuration successfully.${NC}"
        else
            echo -e "${YELLOW}[!] Warning: Issue encountered while copying ${app} config.${NC}"
        fi
    else
        echo -e "${YELLOW}[!] No live configuration directory found for ${app} at ${src_app_dir}.${NC}"
    fi
done

# 2. Standalone Starship TOML Handling (~/.config/starship.toml)
standalone_starship="${SRC_CONFIG_DIR}/starship.toml"
if [ -f "$standalone_starship" ] || [ -L "$standalone_starship" ]; then
    echo -e "${CYAN}[..] Harvesting standalone starship.toml...${NC}"
    mkdir -p "${REPO_CONFIGS}/starship"
    if cp -L --remove-destination "$standalone_starship" "${REPO_CONFIGS}/starship/starship.toml"; then
        chmod u+w "${REPO_CONFIGS}/starship/starship.toml" 2>/dev/null || true
        echo -e "${GREEN}[OK] Harvested standalone starship.toml into ${REPO_CONFIGS}/starship/starship.toml.${NC}"
    else
        echo -e "${YELLOW}[!] Warning: Failed to harvest standalone starship.toml.${NC}"
    fi
fi

# 3. Clean Legacy Hyprland Files (Ensure unified hyprland.lua only)
if [ -f "${REPO_CONFIGS}/hypr/hyprland-gui.lua" ] || [ -L "${REPO_CONFIGS}/hypr/hyprland-gui.lua" ]; then
    rm -f "${REPO_CONFIGS}/hypr/hyprland-gui.lua"
    echo -e "${GREEN}[OK] Purged legacy hyprland-gui.lua from ${REPO_CONFIGS}/hypr/.${NC}"
fi

# 4. Harvest Helper Scripts (~/.local/bin -> ./Scripts/bin)
mkdir -p "$REPO_BIN"
HELPER_SCRIPTS=("gamemode.sh" "toggle-hz.sh" "toggle-opacity.sh")
for script in "${HELPER_SCRIPTS[@]}"; do
    src_script="${SRC_BIN_DIR}/${script}"
    dest_script="${REPO_BIN}/${script}"
    if [ -f "$src_script" ] || [ -L "$src_script" ]; then
        echo -e "${CYAN}[..] Harvesting helper script ${script} from ${src_script}...${NC}"
        if cp -L --remove-destination "$src_script" "$dest_script"; then
            chmod u+w "$dest_script" 2>/dev/null || true
            echo -e "${GREEN}[OK] Harvested ${script} successfully.${NC}"
        else
            echo -e "${YELLOW}[!] Warning: Failed to harvest ${script}.${NC}"
        fi
    else
        echo -e "${YELLOW}[!] Helper script not found at ${src_script}, skipping.${NC}"
    fi
done

echo -e "${GREEN}[OK] Live repository configuration harvesting complete.${NC}"
