#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Fastfetch Banner, Starship & Script Aliases
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

ASCII_SRC="${REPO_ROOT}/ascii_arts"
COSMOS_BASE="${XDG_CONFIG_HOME:-$HOME/.config}/Cosmos"
ASCII_DEST="${COSMOS_BASE}/ascii_arts"
COSMOS_SCRIPTS_DEST="${COSMOS_BASE}/Scripts"

echo -e "${CYAN}[..] Configuring Dynamic ASCII Art, Script Aliases & Shell . . . .${NC}"

# 1. Sync ASCII Art Files
if [ -L "$ASCII_DEST" ]; then
    rm -f "$ASCII_DEST"
fi

mkdir -p "$ASCII_DEST"
if [ -d "$ASCII_SRC" ]; then
    if cp -rL --remove-destination "$ASCII_SRC"/. "$ASCII_DEST"/; then
        chmod -R u+w "$ASCII_DEST" 2>/dev/null || true
        echo -e "${GREEN}[OK] ASCII art collection synced to ${ASCII_DEST}.${NC}"
    else
        echo -e "${YELLOW}[!] Failed to sync some ASCII art files to ${ASCII_DEST}.${NC}"
    fi
else
    echo -e "${YELLOW}[!] Local ascii_arts directory not found at ${ASCII_SRC}.${NC}"
fi

# 2. Deploy Utility Scripts from ./Scripts and ./nixos/Scripts
if [ -L "$COSMOS_SCRIPTS_DEST" ]; then
    rm -f "$COSMOS_SCRIPTS_DEST"
fi
mkdir -p "$COSMOS_SCRIPTS_DEST"

if [ -d "${REPO_ROOT}/Scripts" ]; then
    cp -rL "${REPO_ROOT}/Scripts"/* "$COSMOS_SCRIPTS_DEST"/ 2>/dev/null || true
fi

if [ -d "${REPO_ROOT}/nixos/Scripts" ]; then
    cp -rL "${REPO_ROOT}/nixos/Scripts"/* "$COSMOS_SCRIPTS_DEST"/ 2>/dev/null || true
fi

chmod +x "$COSMOS_SCRIPTS_DEST"/* 2>/dev/null || true
echo -e "${GREEN}[OK] Synced utility scripts to ${COSMOS_SCRIPTS_DEST}.${NC}"

# 3. Dynamically Generate Script Aliases
SCRIPT_ALIASES=""
declare -A seen_aliases=()

# First pass: extensionless scripts (e.g. nix-rebuild)
for script_file in "$COSMOS_SCRIPTS_DEST"/*; do
    [ -f "$script_file" ] || [ -L "$script_file" ] || continue
    file_name="$(basename "$script_file")"
    if [[ "$file_name" != *.sh && "$file_name" != *.zsh ]]; then
        alias_name="$file_name"
        if [[ "$alias_name" =~ ^[a-zA-Z0-9_-]+$ ]] && [ -z "${seen_aliases[$alias_name]:-}" ]; then
            seen_aliases["$alias_name"]=1
            SCRIPT_ALIASES="${SCRIPT_ALIASES}    alias ${alias_name}='~/.config/Cosmos/Scripts/${file_name}'"$'\n'
        fi
    fi
done

# Second pass: script files with extensions (.sh, .zsh)
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

# 4. Generate Idempotent Shell Injection Block
INJECTION_SNIPPET=$(cat << EOF
# >>> COSMOS_FASTFETCH_BANNER_START >>>
if [[ \$- == *i* ]]; then
    # Dynamic Fastfetch ASCII Banner
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

    # Starship Shell Prompt Initialization
    if command -v starship &>/dev/null; then
        if [ -n "\${ZSH_VERSION:-}" ]; then
            eval "\$(starship init zsh)"
        elif [ -n "\${BASH_VERSION:-}" ]; then
            eval "\$(starship init bash)"
        fi
    fi

    # Cosmos Script Aliases
${SCRIPT_ALIASES}fi
# <<< COSMOS_FASTFETCH_BANNER_END <<<
EOF
)

# 5. Injection & Clean Replacement Function
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

    local has_start=0
    local has_end=0
    grep -q "COSMOS_FASTFETCH_BANNER_START" "$rc_file" && has_start=1 || true
    grep -q "COSMOS_FASTFETCH_BANNER_END" "$rc_file" && has_end=1 || true

    if [ "$has_start" -eq 1 ] && [ "$has_end" -eq 0 ]; then
        echo -e "${RED}[ERR] Malformed Cosmos banner block detected in ${rc_file}: 'COSMOS_FASTFETCH_BANNER_START' found without matching 'COSMOS_FASTFETCH_BANNER_END'.${NC}"
        echo -e "${RED}[ERR] Please fix or remove the malformed marker block manually. Skipping modification of ${rc_file} to prevent config loss.${NC}"
        return 0
    fi

    if [ "$has_start" -eq 1 ] && [ "$has_end" -eq 1 ]; then
        echo -e "${YELLOW}[..] Updating existing Fastfetch banner & aliases in ${rc_file}...${NC}"
        sed -i '/# >>> COSMOS_FASTFETCH_BANNER_START >>>/,/# <<< COSMOS_FASTFETCH_BANNER_END <<</d' "$rc_file"
    elif [ "$has_start" -eq 0 ] && [ "$has_end" -eq 1 ]; then
        echo -e "${YELLOW}[!] Warning: Found orphaned COSMOS_FASTFETCH_BANNER_END in ${rc_file}. Removing marker...${NC}"
        sed -i '/# <<< COSMOS_FASTFETCH_BANNER_END <<</d' "$rc_file"
    fi

    # Clean trailing empty lines before appending to maintain clean formatting
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$rc_file" 2>/dev/null || true
    printf "\n%s\n" "$INJECTION_SNIPPET" >> "$rc_file"
    echo -e "${GREEN}[OK] Injected dynamic banner, Starship & aliases into ${shell_name} (${rc_file}).${NC}"
}

# Apply to active shells in user home
[ -f "$HOME/.bashrc" ] || touch "$HOME/.bashrc"
inject_into_rc "$HOME/.bashrc" "Bash"

if [ -f "$HOME/.zshrc" ] || command -v zsh &>/dev/null; then
    inject_into_rc "$HOME/.zshrc" "Zsh"
fi
