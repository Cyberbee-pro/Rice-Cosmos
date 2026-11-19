#!/usr/bin/env bash

# ==============================================================================
#  COSMO CLI : Standalone Helper Binaries Setup
# ==============================================================================

set -euo pipefail

# Reject root/sudo invocation
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    echo -e "\033[0;31m[ERR] Please do not run this script as root or with sudo.\033[0m" >&2
    echo -e "\033[0;33m[!] Run as your regular desktop user so binaries are deployed to your user environment (~/.local/bin).\033[0m" >&2
    exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/bin" ]; then
    BIN_SRC="$SCRIPT_DIR/bin"
elif [ -d "$SCRIPT_DIR/Scripts/bin" ]; then
    BIN_SRC="$SCRIPT_DIR/Scripts/bin"
elif [ -d "$SCRIPT_DIR/../Scripts/bin" ]; then
    BIN_SRC="$(cd "$SCRIPT_DIR/../Scripts/bin" && pwd)"
elif [ -d "$SCRIPT_DIR/../bin" ]; then
    BIN_SRC="$(cd "$SCRIPT_DIR/../bin" && pwd)"
else
    BIN_SRC="$SCRIPT_DIR/bin"
fi

TARGET_DIR="${HOME}/.local/bin"

echo -e "${CYAN}[..] Deploying Helper Binaries to ${TARGET_DIR} . . . .${NC}"

if [ ! -d "$BIN_SRC" ]; then
    echo -e "${RED}[ERR] Helper scripts directory not found: ${BIN_SRC}${NC}"
    exit 1
fi

mkdir -p "$TARGET_DIR"

for script_file in "$BIN_SRC"/*; do
    [ -f "$script_file" ] || [ -L "$script_file" ] || continue
    script_name="$(basename "$script_file")"
    target_path="${TARGET_DIR}/${script_name}"

    if [ -L "$target_path" ]; then
        rm -f "$target_path"
    fi

    if cp -L --remove-destination "$script_file" "$target_path"; then
        chmod +x "$target_path" 2>/dev/null || true
        echo -e "${GREEN}[OK] Deployed helper binary: ${script_name} -> ${target_path}${NC}"
    else
        echo -e "${YELLOW}[!] Warning: Failed to deploy ${script_name}.${NC}"
    fi
done

chmod +x "$TARGET_DIR"/* 2>/dev/null || true
echo -e "${GREEN}[OK] All helper binaries deployed to ${TARGET_DIR}.${NC}"
