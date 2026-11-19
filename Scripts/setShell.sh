#!/usr/bin/env bash

# ==============================================================================
#  COSMO CLI : Shell Environment Orchestrator (Bash & Zsh)
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}[..] Configuring Shell Environments (Bash & Zsh) . . . .${NC}\n"

bash "$SCRIPT_DIR/setup-bash.sh"

if [ -f "$HOME/.zshrc" ] || command -v zsh &>/dev/null; then
    bash "$SCRIPT_DIR/setup-zsh.sh"
fi

echo -e "\n${GREEN}[OK] Shell configuration complete.${NC}"
