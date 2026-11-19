#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Standalone Zsh Setup
# ==============================================================================

set -euo pipefail

# Reject root/sudo invocation
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    echo -e "\033[0;31m[ERR] Please do not run this script as root or with sudo.\033[0m" >&2
    echo -e "\033[0;33m[!] Run as your regular desktop user. Elevation (sudo) will be prompted automatically if packages need to be installed.\033[0m" >&2
    exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

detect_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        case "${ID:-}:${ID_LIKE:-}" in
            *nixos*|*nix*)
                echo "nixos"
                ;;
            *arch*|*endeavouros*|*manjaro*|*garuda*|*artix*)
                echo "arch"
                ;;
            *)
                if command -v pacman &>/dev/null; then echo "arch";
                elif command -v nix &>/dev/null; then echo "nixos";
                else echo "arch"; fi
                ;;
        esac
    else
        if command -v pacman &>/dev/null; then echo "arch";
        elif command -v nix &>/dev/null; then echo "nixos";
        else echo "arch"; fi
    fi
}

DISTRO="${DISTRO:-$(detect_distro)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/ascii_arts" ]; then
    REPO_ROOT="$SCRIPT_DIR"
elif [ -d "$SCRIPT_DIR/../ascii_arts" ]; then
    REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    REPO_ROOT="$SCRIPT_DIR"
fi

echo -e "${CYAN}[..] Configuring Standalone Zsh Environment (${DISTRO^^}) . . . .${NC}"

# 1. Ensure zsh is installed
if ! command -v zsh &>/dev/null; then
    if [ "$DISTRO" = "arch" ]; then
        echo -e "${YELLOW}[..] zsh is missing. Installing via pacman...${NC}"
        if command -v sudo &>/dev/null; then
            sudo pacman -S --needed --noconfirm zsh
        else
            echo -e "${RED}[ERR] sudo required to install zsh.${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}[!] NixOS manages packages declaratively. Please enable 'programs.zsh.enable = true' in your configuration.nix.${NC}"
    fi
fi

# 2. Sync ascii_arts/ and Scripts/ to ~/.config/Cosmos/
COSMOS_BASE="${XDG_CONFIG_HOME:-$HOME/.config}/Cosmos"
ASCII_SRC="${REPO_ROOT}/ascii_arts"
ASCII_DEST="${COSMOS_BASE}/ascii_arts"
SCRIPTS_SRC="${REPO_ROOT}/Scripts"
COSMOS_SCRIPTS_DEST="${COSMOS_BASE}/Scripts"
NIXOS_SCRIPTS_SRC="${REPO_ROOT}/nixos/Scripts"

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

if [ -d "$NIXOS_SCRIPTS_SRC" ]; then
    echo -e "${CYAN}[..] Syncing NixOS utility scripts to ${COSMOS_SCRIPTS_DEST}...${NC}"
    for script_file in "$NIXOS_SCRIPTS_SRC"/*; do
        [ -f "$script_file" ] || [ -L "$script_file" ] || continue
        base_name="$(basename "$script_file")"
        cp -L --remove-destination "$script_file" "${COSMOS_SCRIPTS_DEST}/${base_name}"
    done
    chmod +x "$COSMOS_SCRIPTS_DEST"/* 2>/dev/null || true
    echo -e "${GREEN}[OK] NixOS utility scripts synced to ${COSMOS_SCRIPTS_DEST}.${NC}"
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

# 4. Strict marker order validation for ~/.zshrc
ZSHRC="$HOME/.zshrc"
start_count=0
end_count=0
start_line=0
end_line=0

if [ -f "$ZSHRC" ] || [ -L "$ZSHRC" ]; then
    read -r start_count end_count start_line end_line < <(awk '
        /COSMOS_FASTFETCH_BANNER_START/ { start_count++; if (start_line == 0) start_line = NR }
        /COSMOS_FASTFETCH_BANNER_END/   { end_count++; if (end_line == 0) end_line = NR }
        END { printf "%d %d %d %d\n", start_count, end_count, start_line, end_line }
    ' "$ZSHRC")
fi

if [ "$start_count" -eq 0 ] && [ "$end_count" -eq 0 ]; then
    : # Brand new injection, valid
elif [ "$start_count" -eq 1 ] && [ "$end_count" -eq 1 ] && [ "$start_line" -lt "$end_line" ]; then
    : # Existing valid block to replace
else
    echo -e "${RED}[ERR] Malformed Cosmos banner markers in ${ZSHRC} (start_count=${start_count}, end_count=${end_count}, start_line=${start_line}, end_line=${end_line}).${NC}" >&2
    echo -e "${RED}[ERR] Aborting modification to prevent config corruption. Please manually fix or remove the markers in ${ZSHRC}.${NC}" >&2
    exit 1
fi

# 5. Non-destructively back up ~/.zshrc
if [ -L "$ZSHRC" ]; then
    backup_path="${ZSHRC}.backup_$(date +%Y%m%d_%H%M%S)"
    count=1
    while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
        backup_path="${ZSHRC}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
        count=$((count + 1))
    done
    echo -e "${YELLOW}[..] Backing up symlinked ~/.zshrc to ${backup_path}...${NC}"
    cp -L "$ZSHRC" "$backup_path"
    target_link="$(readlink -f "$ZSHRC")"
    rm -f "$ZSHRC"
    if [ -f "$target_link" ]; then
        cp "$target_link" "$ZSHRC"
    else
        touch "$ZSHRC"
    fi
elif [ -f "$ZSHRC" ]; then
    backup_path="${ZSHRC}.backup_$(date +%Y%m%d_%H%M%S)"
    count=1
    while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
        backup_path="${ZSHRC}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
        count=$((count + 1))
    done
    echo -e "${YELLOW}[..] Backing up existing ~/.zshrc to ${backup_path}...${NC}"
    cp "$ZSHRC" "$backup_path"
else
    touch "$ZSHRC"
fi
chmod u+w "$ZSHRC" 2>/dev/null || true

# 6. Idempotently inject Cosmos banner, Starship prompt init, and aliases into ~/.zshrc
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
        eval "\$(starship init zsh)"
    fi

    # Cosmos Script Aliases
${SCRIPT_ALIASES}fi
# <<< COSMOS_FASTFETCH_BANNER_END <<<
EOF
)

if [ "$start_count" -eq 1 ] && [ "$end_count" -eq 1 ]; then
    echo -e "${YELLOW}[..] Updating existing Cosmos banner & aliases in ${ZSHRC}...${NC}"
    sed -i "${start_line},${end_line}d" "$ZSHRC"
else
    echo -e "${CYAN}[..] Adding Cosmos banner & aliases to ${ZSHRC}...${NC}"
fi

sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$ZSHRC" 2>/dev/null || true
printf "\n%s\n" "$INJECTION_SNIPPET" >> "$ZSHRC"
echo -e "${GREEN}[OK] Standalone Zsh setup complete (~/.zshrc updated).${NC}"
