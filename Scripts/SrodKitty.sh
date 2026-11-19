#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Dotfiles & Helper Binaries Orchestration Wrapper
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}[..] Deploying All Dotfiles & Binaries via Component Scripts . . . .${NC}\n"

bash "$SCRIPT_DIR/setup-kitty.sh"
bash "$SCRIPT_DIR/setup-fastfetch.sh"
bash "$SCRIPT_DIR/setup-starship.sh"
bash "$SCRIPT_DIR/setup-nvim.sh"
bash "$SCRIPT_DIR/setup-caelestia.sh"
bash "$SCRIPT_DIR/setup-bin.sh"

echo -e "\n${GREEN}[OK] All dotfiles and helper binaries deployed successfully.${NC}"
