#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Standalone Bash Setup
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/ascii_arts" ]; then
    REPO_ROOT="$SCRIPT_DIR"
elif [ -d "$SCRIPT_DIR/../ascii_arts" ]; then
    REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    REPO_ROOT="$SCRIPT_DIR"
fi

echo -e "${CYAN}[..] Configuring Standalone Bash Environment . . . .${NC}"

# 1. Ensure bash is installed via pacman
if ! command -v bash &>/dev/null; then
    echo -e "${YELLOW}[..] bash is missing. Installing via pacman...${NC}"
    if [ "$EUID" -eq 0 ]; then
        pacman -S --needed --noconfirm bash
    elif command -v sudo &>/dev/null; then
        sudo pacman -S --needed --noconfirm bash
    else
        echo -e "${RED}[ERR] Root privileges or sudo required to install bash.${NC}"
        exit 1
    fi
fi

# 2. Sync ascii_arts/ and Scripts/ to ~/.config/Cosmos/
COSMOS_BASE="${XDG_CONFIG_HOME:-$HOME/.config}/Cosmos"
ASCII_SRC="${REPO_ROOT}/ascii_arts"
ASCII_DEST="${COSMOS_BASE}/ascii_arts"
SCRIPTS_SRC="${REPO_ROOT}/Scripts"
COSMOS_SCRIPTS_DEST="${COSMOS_BASE}/Scripts"

mkdir -p "$COSMOS_BASE" "$ASCII_DEST" "$COSMOS_SCRIPTS_DEST"

if [ -d "$ASCII_SRC" ]; then
    echo -e "${CYAN}[..] Syncing ASCII art assets to ${ASCII_DEST}...${NC}"
    cp -rL --remove-destination "$ASCII_SRC"/. "$ASCII_DEST"/
    chmod -R u+w "$ASCII_DEST" 2>/dev/null || true
    echo -e "${GREEN}[OK] ASCII art collection synced.${NC}"
fi

if [ -d "$SCRIPTS_SRC" ]; then
    echo -e "${CYAN}[..] Syncing utility scripts to ${COSMOS_SCRIPTS_DEST}...${NC}"
    for script_file in "$SCRIPTS_SRC"/*.sh; do
        [ -f "$script_file" ] || continue
        base_name="$(basename "$script_file")"
        cp -L --remove-destination "$script_file" "${COSMOS_SCRIPTS_DEST}/${base_name}"
    done
    chmod +x "$COSMOS_SCRIPTS_DEST"/*.sh 2>/dev/null || true
    echo -e "${GREEN}[OK] Utility scripts synced to ${COSMOS_SCRIPTS_DEST}.${NC}"
fi

# 3. Generate script aliases from ~/.config/Cosmos/Scripts/
SCRIPT_ALIASES=""
declare -A seen_aliases=()

for script_file in "$COSMOS_SCRIPTS_DEST"/*; do
    [ -f "$script_file" ] || [ -L "$script_file" ] || continue
    file_name="$(basename "$script_file")"
    alias_name="${file_name%.sh}"
    alias_name="${alias_name%.zsh}"
    if [[ "$alias_name" =~ ^[a-zA-Z0-9_-]+$ ]] && [ -z "${seen_aliases[$alias_name]:-}" ]; then
        seen_aliases["$alias_name"]=1
        SCRIPT_ALIASES="${SCRIPT_ALIASES}    alias ${alias_name}='~/.config/Cosmos/Scripts/${file_name}'"$'\n'
    fi
done

# 4. Non-destructively back up ~/.bashrc
BASHRC="$HOME/.bashrc"
if [ -L "$BASHRC" ]; then
    backup_path="${BASHRC}.backup_$(date +%Y%m%d_%H%M%S)"
    count=1
    while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
        backup_path="${BASHRC}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
        count=$((count + 1))
    done
    echo -e "${YELLOW}[..] Backing up symlinked ~/.bashrc to ${backup_path}...${NC}"
    cp -L "$BASHRC" "$backup_path"
    target_link="$(readlink -f "$BASHRC")"
    rm -f "$BASHRC"
    if [ -f "$target_link" ]; then
        cp "$target_link" "$BASHRC"
    else
        touch "$BASHRC"
    fi
elif [ -f "$BASHRC" ]; then
    backup_path="${BASHRC}.backup_$(date +%Y%m%d_%H%M%S)"
    count=1
    while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
        backup_path="${BASHRC}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
        count=$((count + 1))
    done
    echo -e "${YELLOW}[..] Backing up existing ~/.bashrc to ${backup_path}...${NC}"
    cp "$BASHRC" "$backup_path"
else
    touch "$BASHRC"
fi
chmod u+w "$BASHRC" 2>/dev/null || true

# 5. Idempotently inject Cosmos banner, Starship prompt init, and aliases into ~/.bashrc
INJECTION_SNIPPET=$(cat << EOF
# >>> COSMOS_FASTFETCH_BANNER_START >>>
if [[ \$- == *i* ]]; then
    # Dynamic Fastfetch ASCII Banner (if fastfetch is installed)
    if [ -t 1 ] && command -v fastfetch &>/dev/null; then
        _cosmos_ascii_dir="\${XDG_CONFIG_HOME:-\$HOME/.config}/Cosmos/ascii_arts"
        if [ -d "\$_cosmos_ascii_dir" ] && [ "\$(ls -A "\$_cosmos_ascii_dir" 2>/dev/null)" ]; then
            _cosmos_art="\$(find "\$_cosmos_ascii_dir" -type f 2>/dev/null | shuf -n 1 || true)"
            if [ -n "\$_cosmos_art" ] && [ -f "\$_cosmos_art" ]; then
                fastfetch --logo "\$_cosmos_art"
            else
                fastfetch
            fi
            unset _cosmos_art
        else
            fastfetch
        fi
        unset _cosmos_ascii_dir
    fi

    # Starship Shell Prompt Initialization (if starship is installed)
    if command -v starship &>/dev/null; then
        eval "\$(starship init bash)"
    fi

    # Cosmos Script Aliases
${SCRIPT_ALIASES}fi
# <<< COSMOS_FASTFETCH_BANNER_END <<<
EOF
)

has_start=0
has_end=0
if grep -q "COSMOS_FASTFETCH_BANNER_START" "$BASHRC"; then
    has_start=1
fi
if grep -q "COSMOS_FASTFETCH_BANNER_END" "$BASHRC"; then
    has_end=1
fi

if [ "$has_start" -eq 1 ] && [ "$has_end" -eq 0 ]; then
    echo -e "${RED}[ERR] Malformed Cosmos banner block in ${BASHRC}. Skipping modification to avoid config corruption.${NC}"
    exit 0
fi

if [ "$has_start" -eq 1 ] && [ "$has_end" -eq 1 ]; then
    echo -e "${YELLOW}[..] Updating existing Cosmos banner & aliases in ${BASHRC}...${NC}"
    sed -i '/# >>> COSMOS_FASTFETCH_BANNER_START >>>/,/# <<< COSMOS_FASTFETCH_BANNER_END <<</d' "$BASHRC"
elif [ "$has_start" -eq 0 ] && [ "$has_end" -eq 1 ]; then
    sed -i '/# <<< COSMOS_FASTFETCH_BANNER_END <<</d' "$BASHRC"
fi

sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$BASHRC" 2>/dev/null || true
printf "\n%s\n" "$INJECTION_SNIPPET" >> "$BASHRC"
echo -e "${GREEN}[OK] Standalone Bash setup complete (~/.bashrc updated).${NC}"
