#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Fastfetch Dynamic ASCII Shell Banner
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASCII_SRC="${SCRIPT_DIR}/ascii_arts"
ASCII_DEST="${XDG_CONFIG_HOME:-$HOME/.config}/Cosmos/ascii_arts"

echo -e "${CYAN}[..] Configuring Dynamic ASCII Art & Shell Launchers . . . .${NC}"

# 1. Sync ASCII Art Files
if [ -L "$ASCII_DEST" ]; then
    rm -f "$ASCII_DEST"
fi

mkdir -p "$ASCII_DEST"
if [ -d "$ASCII_SRC" ]; then
    if cp -r --remove-destination "$ASCII_SRC"/. "$ASCII_DEST"/; then
        echo -e "${GREEN}[OK] ASCII art collection synced to ${ASCII_DEST}.${NC}"
    else
        echo -e "${YELLOW}[!] Failed to sync some ASCII art files to ${ASCII_DEST}.${NC}"
    fi
else
    echo -e "${YELLOW}[!] Local ascii_arts directory not found in repo. Utilizing existing configs.${NC}"
fi

# 2. Deploy Fastfetch & Starship Configs
CONFIGS_DIR="${SCRIPT_DIR}/configs"
FASTFETCH_SRC="${CONFIGS_DIR}/fastfetch"
FASTFETCH_DEST="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch"
STARSHIP_SRC="${CONFIGS_DIR}/starship/starship.toml"
STARSHIP_DEST="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"

if [ -d "$FASTFETCH_SRC" ]; then
    if [ -L "$FASTFETCH_DEST" ]; then
        rm -f "$FASTFETCH_DEST"
    fi
    mkdir -p "$FASTFETCH_DEST"
    if cp -r --remove-destination "$FASTFETCH_SRC"/. "$FASTFETCH_DEST"/; then
        chmod -R u+w "$FASTFETCH_DEST" 2>/dev/null || true
        echo -e "${GREEN}[OK] Fastfetch configuration deployed to ${FASTFETCH_DEST}.${NC}"
    else
        echo -e "${YELLOW}[!] Warning: Could not copy Fastfetch configs to ${FASTFETCH_DEST}.${NC}"
    fi
fi

if [ -f "$STARSHIP_SRC" ]; then
    mkdir -p "$(dirname "$STARSHIP_DEST")"
    if [ -L "$STARSHIP_DEST" ]; then
        rm -f "$STARSHIP_DEST"
    fi
    if cp --remove-destination "$STARSHIP_SRC" "$STARSHIP_DEST"; then
        chmod u+w "$STARSHIP_DEST" 2>/dev/null || true
        echo -e "${GREEN}[OK] Starship configuration deployed to ${STARSHIP_DEST}.${NC}"
    else
        echo -e "${YELLOW}[!] Warning: Could not copy Starship config to ${STARSHIP_DEST}.${NC}"
    fi
fi
# 3. Generate Isolated Injection Block (Protected for non-interactive shells)
INJECTION_SNIPPET=$(cat << 'EOF'
# >>> COSMOS_FASTFETCH_BANNER_START >>>
if [[ $- == *i* ]] && [ -t 1 ] && command -v fastfetch &>/dev/null; then
    _cosmos_ascii_dir="${XDG_CONFIG_HOME:-$HOME/.config}/Cosmos/ascii_arts"
    if [ -d "$_cosmos_ascii_dir" ] && [ "$(ls -A "$_cosmos_ascii_dir" 2>/dev/null)" ]; then
        _cosmos_art="$(find "$_cosmos_ascii_dir" -type f 2>/dev/null | shuf -n 1 || true)"
        if [ -n "$_cosmos_art" ] && [ -f "$_cosmos_art" ]; then
            fastfetch --logo "$_cosmos_art"
        else
            fastfetch
        fi
        unset _cosmos_art
    else
        fastfetch
    fi
    unset _cosmos_ascii_dir
fi
# <<< COSMOS_FASTFETCH_BANNER_END <<<
EOF
)

# 4. Clean Insertion / Replacement Function
inject_into_rc() {
    local rc_file="$1"
    local shell_name="$2"

    if [ -L "$rc_file" ]; then
        local target_link
        target_link="$(readlink -f "$rc_file")"
        rm -f "$rc_file"
        if [ -f "$target_link" ]; then
            cp "$target_link" "$rc_file"
            chmod u+w "$rc_file"
        else
            touch "$rc_file"
        fi
    elif [ ! -f "$rc_file" ]; then
        touch "$rc_file"
    else
        chmod u+w "$rc_file" 2>/dev/null || true
    fi

    if grep -q "COSMOS_FASTFETCH_BANNER_START" "$rc_file"; then
        echo -e "${YELLOW}[..] Updating existing Fastfetch banner in ${rc_file}...${NC}"
        sed -i '/# >>> COSMOS_FASTFETCH_BANNER_START >>>/,/# <<< COSMOS_FASTFETCH_BANNER_END <<</d' "$rc_file"
    fi

    # Clean trailing newlines before appending to guarantee strict idempotency
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$rc_file" 2>/dev/null || true
    printf "\n%s\n" "$INJECTION_SNIPPET" >> "$rc_file"
    echo -e "${GREEN}[OK] Injected dynamic Fastfetch startup into ${shell_name} (${rc_file}).${NC}"
}

# Apply to all active shells present in user home
[ -f "$HOME/.bashrc" ] || touch "$HOME/.bashrc"
inject_into_rc "$HOME/.bashrc" "Bash"

if [ -f "$HOME/.zshrc" ] || command -v zsh &>/dev/null; then
    inject_into_rc "$HOME/.zshrc" "Zsh"
fi