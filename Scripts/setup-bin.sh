#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Standalone Helper Binaries Setup
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/bin" ]; then
    REPO_ROOT="$SCRIPT_DIR"
elif [ -d "$SCRIPT_DIR/../Scripts/bin" ]; then
    REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    REPO_ROOT="$SCRIPT_DIR"
fi

BIN_SRC="${REPO_ROOT}/Scripts/bin"
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
