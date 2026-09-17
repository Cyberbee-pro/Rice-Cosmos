#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Wallpaper Deployer (Preserves Folder Hierarchy)
# ==============================================================================

set -euo pipefail

# ANSI Color Palette
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/Wallpapers"
TARGET_DIR="${HOME}/Pictures/Wallpapers"

echo -e "${CYAN}[..] Deploying wallpapers with full folder structure to ${TARGET_DIR} . . . .${NC}"

if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}[ERR] Wallpapers source directory not found: ${SOURCE_DIR}${NC}"
    exit 1
fi

if [ -L "$TARGET_DIR" ]; then
    if [ -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}[..] Preserving valid symlink: ${TARGET_DIR} -> $(readlink -f "$TARGET_DIR")${NC}"
    else
        rm -f "$TARGET_DIR"
    fi
fi

mkdir -p "$TARGET_DIR"

found_count=0

# Iterate through every matching wallpaper/video file relative to SOURCE_DIR
while IFS= read -r -d '' file; do
    rel_path="${file#"$SOURCE_DIR"/}"
    dest_path="${TARGET_DIR}/${rel_path}"
    dest_dir="$(dirname "$dest_path")"

    mkdir -p "$dest_dir"
    cp -u --remove-destination "$file" "$dest_path"
    found_count=$((found_count + 1))
done < <(find "$SOURCE_DIR" -type f \( \
    -iname "*.jpg" -o \
    -iname "*.jpeg" -o \
    -iname "*.png" -o \
    -iname "*.gif" -o \
    -iname "*.mp4" -o \
    -iname "*.webp" \
\) -print0)

echo -e "${GREEN}[OK] Successfully deployed ${found_count} wallpapers (hierarchy preserved) to: ${TARGET_DIR}/${NC}"