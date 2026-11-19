#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : System Theme & Shell Installer (Arch Linux)
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOAD_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/cosmos/downloads"

echo -e "${CYAN}[..] Running System Theme & Display Manager Installation . . . .${NC}"

RUN_AS_ROOT="sudo"
if [ "$EUID" -eq 0 ]; then
    RUN_AS_ROOT=""
elif ! command -v sudo &>/dev/null; then
    echo -e "${RED}[ERR] sudo command not found. Root privileges required.${NC}"
    exit 1
fi

# 1. CyberGRUB-2077 (if present in download cache)
if [ -d "$DOWNLOAD_CACHE/CyberGRUB-2077" ]; then
    echo -e "${CYAN}[..] Installing CyberGRUB Theme...${NC}"
    (
        cd "$DOWNLOAD_CACHE/CyberGRUB-2077"
        chmod +x install.sh 2>/dev/null || true
        # shellcheck disable=SC2086
        $RUN_AS_ROOT bash ./install.sh -L arasaka
    )
    echo -e "${GREEN}[OK] CyberGRUB-2077 installed.${NC}"
else
    echo -e "${YELLOW}[!] CyberGRUB source not found in cache. Skipping GRUB theme.${NC}"
fi

# 2. SDDM & QYLock Theme
bash "$SCRIPT_DIR/setup-sddm.sh"

# 3. Caelestia Shell Setup
bash "$SCRIPT_DIR/setup-caelestia.sh"

echo -e "\n${GREEN}[OK] System themes & display manager installed successfully.${NC}"
