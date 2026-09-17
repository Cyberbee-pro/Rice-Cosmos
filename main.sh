#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Master Orchestrator
# ==============================================================================

set -euo pipefail

# Script Directory Resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure companion scripts are executable
chmod +x "$SCRIPT_DIR"/download.sh "$SCRIPT_DIR"/install.sh "$SCRIPT_DIR"/SrodKitty.sh "$SCRIPT_DIR"/setShell.sh "$SCRIPT_DIR"/syncWallpapers.sh 2>/dev/null || true

# ANSI Palette (No Emojis)
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_RED='\033[38;5;203m'
C_GREEN='\033[38;5;120m'
C_YELLOW='\033[38;5;221m'
C_BLUE='\033[38;5;75m'
C_PURPLE='\033[38;5;176m'
C_CYAN='\033[38;5;117m'
C_DARK='\033[38;5;238m'

# Character Art Palette
B_CYAN='\033[38;5;81m'
B_TEAL='\033[38;5;44m'
B_MINT='\033[38;5;121m'
B_PINK='\033[38;5;212m'
B_PURPLE='\033[38;5;141m'
B_VIOLET='\033[38;5;99m'

# Global Cursor Restore Trap
cleanup() {
    tput cnorm 2>/dev/null || printf "\033[?25h"
}
trap cleanup EXIT INT TERM

# Primary Distribution Detection via /etc/os-release
detect_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        case "${ID:-}:${ID_LIKE:-}" in
            *arch*|*endeavouros*|*manjaro*|*garuda*|*artix*)
                echo "arch"
                ;;
            *nixos*|*nix*)
                echo "nix"
                ;;
            *)
                if command -v pacman &>/dev/null; then echo "arch";
                elif command -v nix &>/dev/null; then echo "nix";
                else echo "arch"; fi
                ;;
        esac
    else
        if command -v pacman &>/dev/null; then echo "arch";
        elif command -v nix &>/dev/null; then echo "nix";
        else echo "arch"; fi
    fi
}

export DISTRO="${DISTRO:-$(detect_distro)}"

render_character_art() {
    echo -e "${B_CYAN}⠋⠌⠁⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠠⠀⠄⠤⠐⡀⠄⠠⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_CYAN}⣁⠠⢀⢀⠀⢀⠠⠀⠀⠠⠀⠀⡀⠠⠀⠀⠠⠀⢀⠀⠀⠀⠀⡀⠀⠄⠠⠀⠀⠤⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠄⠀⡠⠀⠀⡠⠀⡠⠐⢌⠠⠄⡔⠠⢔⠠⠤⠡⠆⢠⠀⠄⠀⠀⠀⡀⠀⠀⡀⠠⠀⠀⢀⠀⢀⠠⠀⠀⠄⠠⠀⡀⠀⠠⠀⠀⠀⠀⠀⠠⠀⢀⠀⠀⡀⠀⠠⠀⠀⠠⠀⠀⡀⢀⠀⠄⠀⠀⠄⠀⡀⢀⠀⠠⠀⢀⠠⠀⠀⡀⢀⠀⡀⠠⠀⠀⠄"
    echo -e "${B_TEAL}⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠀⠀⠀⠀⠀⠀⠄⠀⠀⠀⣀⡀⠀⠀⢂⠠⠈⡀⠠⠀⠀⠀⠀⠀⠠⠐⠀⠂⠠⠐⠀⠄⠀⠀⠠⠀⢀⢂⠀⢊⠀⠄⢀⠑⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠀⠀⠀⡀⠐⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_TEAL}⠤⠀⠀⠂⠀⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠈⠀⠀⣀⣤⣀⠀⠀⠀⠀${B_PINK}⣔⣿⣿⡿⠿⣶⣄⡀${B_TEAL}⠅⡐⢀⡀⠀⠀⡀⠀⠁⢌⠈⡄⢁⠂⠂⢌⠠⡉⢀⠁⠤⡈⡈⢀⠂⠀⠀⠀⠀⢀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠈⡀⠀⠈⠀⠌⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_MINT}⠢⠐⠀⢀⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀⠠⠀⠁⠠⠀⠄⠀⠀⠁${B_PINK}⢼⡿⠉⠙⠱⠀⠀⢰⣿⢿⡁⠀⠀⠀⠈⠻⣆${B_MINT}⠐⠀⠄⡁⢂⠀⠀⠀⠀⠠⢀⠂⠠⠌⢠⠐⠄⠂⠍⡠⠐⡀⠀⠀⠀⠀⠐⠀⠀⠀⠄⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠠⠐⠀⠠⢀⠡⠉⠌⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_MINT}⡑⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠀⠀⠀⢀⣤⠀⠈⢀⢀⠘${B_PINK}⣿⣄⠀⠀⠀⡀⠹⣿⣀⠀⢀⠀⠀⠀⠀⢻⣇${B_MINT}⠈⡀⠠⠀⠂⡀⠂⠀⠁⠂⠌⡐⠂⠄⠂⡌⠑⠠⠀⢀⠠⠀⠀⠀⠀⠀⠀⡐⠈⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠐⠀⢂⠔⠁⠂⠄⠁⠄⡈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_CYAN}⢌⠀⠐⠀⠀⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠐⠀⠀⠈${B_PINK}⢷⣄⠘⣿⡉⠀⠈⠻⣷⣄⡀⢀⣤⣤⣬⣤⣄⣀⣀⠀⠀⠈⣿⡆${B_CYAN}⠀⠀⠁⠔⠀⠀⠀⠠⠁⢂⠀⠂⠌⠑⣀⢉⠐⣁⠠⢀⠀⠂⠀⢀⠀⡀⢠⠂⠁⡀⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⡀⠠⠀⠋⣀⠂⢉⠂⠐⡀⠁⠀⠈⠀⠀⠉⠐⠠⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_CYAN}⠢⠀⠀⠈⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀${B_PINK}⣾⣰⡋⠁⠀⠀⠉⠓⠮⢿⣦⣤⣤⣌⣛⣿⣿⣥⣄⣀⣀⣀⡈⠉⠻⣦⣤⣿⣯${B_CYAN}⠀⠄⠀⠀⠈⢀⠀⠄⡁⠂⢀⠀⠌⢠⠀⠄⡁⠠⠐⠄⡂⠡⢀⠄⢂⠀⢂⠌⢢⠠⠑⠠⢄⡈⠀⠀⢀⠠⠐⢀⠀⠠⠒⡐⢠⠉⠠⠀⠂⠠⠀⠀⠀⠀⠀⠐⠈⠀⠀⠀⠁⠈⠀⡀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⡑⠀⠀⠁⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣆${B_PINK}⠙⢷⣷⣤⣀⠀⠀⠐⠂⠀⣉⣛⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣶⣄⢹⣿⣯${B_PURPLE}⠀⠀⠀⠀⠀⠂⠐⠠⠀⠂⠀⠄⠈⠄⠂⠐⠀⠐⠈⠄⠐⡐⠀⢂⠂⠌⠄⠂⠡⠄⠁⠂⡀⠈⠢⢉⠄⠤⠐⠠⠤⣋⠐⢣⡀⠐⠠⠀⡁⠀⠐⠀⢀⠀⠄⠀⠀⠀⠀⠀⠀⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⣌⠀⠀⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀${B_PINK}⠈⠛⢳⣶⣮⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣻⣿⣷⣿⣿⣿⣿⡇${B_PURPLE}⠈⠀⠀⠀⠐⡀⠁⢀⠐⠀⠂⠈⡀⠈⠀⡈⠀⠀⠈⢀⠀⢣⡄⢡⢈⠐⡉⠂⡌⢑⡀⠀⠐⡀⢀⢣⠀⡌⠀⠀⠀⠙⠂⣤⠁⢒⢠⠈⢀⠀⡄⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⢮⠀⠀⠆⠀⡃⠀⠀⠀⠀⠀⠀⠀⠀${B_PINK}⣀⣴⣶⣷⣶⣤⣄⣀⠉⢻⣿⣯⣍⣉⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣃${B_PURPLE}⠀⠀⠀⠀⠀⠁⠃⢨⠀⠀⠃⠰⡁⢣⠀⢁⢠⠰⠀⢘⡜⠀⢠⠰⠈⡀⠁⠀⠘⡌⡁⠰⠀⠁⠘⠀⡛⠀⠀⠀⡄⠀⠰⡈⡞⣬⡳⠶⢨⠃⢠⠀⡄⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠃⡘⠀⢠⠀⢠⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_VIOLET}⠣⠀⠀⢀⠀⡁⠀⠀⠀⠀⠀⠀⠀${B_PINK}⣘⣿⣿⣧⣄⡉⠙⠻⣿⣿⣧⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡀${B_VIOLET}⠀⠀⠀⠀⠄⠀⠠⠀⠀⠀⠁⡀⢀⠈⠠⠀⠛⠈⠀⠀⠀⠀⠀⡁⠀⠠⠀⠀⡁⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠠⠀⣅⠣⠄⡅⢃⠏⢀⡠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_VIOLET}⠱⠀⠈⠀⠀⠄⠀⠀⠀⠀⠀⠀${B_PINK}⠸⠟⢟⡿⢿⣿⣿⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⢷⣄${B_VIOLET}⠐⠀⠀⠀⠀⠠⠀⠀⠀⠀⣠⣤⡀⠂⠄⠀⠀⠀⠀⠀⠀⢀⠀⠈⠐⠂⠄⡄⠄⠂⠄⠠⠀⠀⠀⠀⠠⠀⠐⠠⢀⠐⠠⠄⠂⠠⠀⠄⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_VIOLET}⡑⠀⠀⠐⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀${B_PINK}⠈⠙⠛⠿⠟⠻⠻⠿⢿⣷⣤⣤⣥⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⡄⢻⡄${B_VIOLET}⠀⠀⣀⣶⣴⠀⢁⡈⣀⣿⣿⣧⠀⣁⣁⡀⣀⣀⣤⣤⣤⣤⡄⠂⠈⠀⠀⠈⠑⠂⠁⠂⢀⠀⠀⠐⠀⢁⡀⠠⠀⠔⠀⠊⠀⠀⠀⠐⠀⠀⠐⡀⠂⠠⠀⠐⠀⠂⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⢌⠀⠐⠀⠀⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀${B_PINK}⢤⣶⡾⠷⠶⢶⣶⣤⣤⣌⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣥⣿⢿⣿⣿⢹⢇⡼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣿⡇${B_PURPLE}⠀⣀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⢀⠈⠀⠠⠁⠈⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠠⠁⠀⢁⠀⡀⠀⠀⠀⠄⠁⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⠢⠀⢀⠠⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀${B_PINK}⠘⠳⠀⠀⠀⠸⣤⣴⡾⢿⣛⣛⣻⣿⢶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣉⡽⢃⣨⣿⣗⠞⠉⠀⠉⠉⢉⣽⣿⣿⠀⣻⣿⣏⡉⠫⠉⠀⣿⣿⡇⠀⢈⣍⣍⣍⢉⣁⣀⣀⣀⣀⣀⣠⣀⣀⣀⣀⣤⣁⣀⣀⣀⣄⣀⣀⣀⣀⡀${B_PURPLE}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PINK}⡑⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⣾⡿⣻⠿⠛⢋⣹⡿⠿⠛⠻⢟⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣴⣿⣿⣿⣿⣶⣶⣶⣶⣾⣿⣿⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣤⣤⣤⣦⣤⣦⣶⣴⣦⣶⣴⣦⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣿⡿⣿⣿⢿⣷⣶⡀⠂⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PINK}⢌⠀⠀⠂⠀⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠻⠄⣤⡟⠉⠀⠀⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⠛⠛⢛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠻⠿⠿⠿⠿⠿⠿⠛⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PINK}⠢⠀⠀⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠀⠀⣸⣿⣀⡀⠐⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⣿⡟⢻⣿⣿⣿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠉⠈⠈⠁⠈⠁⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⡑⠀⠠⠀⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠀⠀⠀⠀⠻⣿⠾⠛⠀⢀${B_PINK}⣿⣿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣷⣼⣿⣿⣿⣧${B_PURPLE}⠈⠹⡻⠿⣿⣟⡻⣟⣛⣻⣟⠿⣿⣿⣿⣿⣿⣿⣿⣷⣿⣿⣿⣿⣿⢿⡞⠹⢿⠿⣿⠿⠿⠿⠿⠿⠻⠟⠛⠛⠛⠙⠿⠟⠁⠙⠆⠁⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠐⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⢌⠀⠀⠠⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠈⠀⡀⠀⠈${B_PINK}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣟⣿⣿⣿⣿⢹⢿⣇⡴⢷⣾⣻⣥⣿⡝⣻⣟⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟${B_PURPLE}⠀⠀⠀⣴⠏⠀⡀⠀⠀⢀⠀⠠⢈⠌⡁⠉⠤⠀⠁⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⢀⠀⡀⠀⠀⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⢺⣿⡆⠀⠀⣀⣰${B_PINK}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣞⣽⣿⣿⣿⣯⠿⣿⣹⣿⣼⣿⢷⣿⢯⣭⠷⣿⣿⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃${B_PURPLE}⠀⢠⣾⠏⠀⠀⣀⣔⠈⠤⢡⡍⢠⠐⠀⠢⠄⡁⢐⠄⡀⢀⡀⠠⢀⠀⢀⠀⠀⠀⠀⡂⢈⠤⠀⠆⡒⠂⠄⠀⠠⠀⠀⢀⠠⡐⢈⠡⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_VIOLET}⠀⠀⡀⠀⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠠⠀⠹⠿⣷⠀⠀⠀⠛⠃⣤⠀⠹${B_PINK}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣻⣿⡿⠟⠻⣿⣿⣿⡿⠋${B_VIOLET}⠔⠠⠄⠄⠠${B_PINK}⣿⡿⠿⠿⠟⠛⠋⢋⠉⡉⢀⣰⡿⠁${B_VIOLET}⠄⢐⣶⣿⠟⠁⠁⠄⠐⠢⠈⠌⣁⠐⡀⢂⠌⠄⠀⠀⣀⠖⠊⠀⠀⠀⠀⠀⠖⠁⠀⠒⠠⠈⠑⠬⢁⡂⡐⠌⠄⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_VIOLET}⠀⠀⢐⡠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡜⠻⣥⡀⠀⠀⠀⠀⠤⣬⣦⢠${B_PINK}⣬⣿⣝⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⡟⠁${B_VIOLET}⠀⠒⠀⠀⠉⣰⡀⠁⢈⣀⠌⠘⡀⣀⠐⠂⢉⠠⡈⠀⠂⠐⢀${B_PINK}⣼⠟⠀⢀⣾⣿⠟⠁${B_VIOLET}⠀⠀⠀⠀⠀⠀⠁⠐⠀⠠⠀⠀⠀⠀⠠⠁⠀⣀⠀⡀⠂⢁⠉⠀⠀⠈⠀⠀⠐⠀⠀⠀⠀⠀⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_VIOLET}⠀⠈⠁⠀⠀⠄⠈⠀⠀⠀⠀⠀⠘⠓⠀⠛⠀⠀⠀⠀⣿⡇⢈⠄⡈⠉⢿⠰${B_PINK}⢿⣿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡯⢍⣿⣷⣶⣾⣿⣾⣶⣶⣆⠿⠇${B_VIOLET}⠀⠄⣀⠔⠂⠔⡠⠉⠠⢀⡀⠤⠀${B_PINK}⣖⣤⡿⠃⡀⠰⡿⠛⠁${B_VIOLET}⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⡀⠐⠀⣠⠁⢄⠨⠀⠆⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⠀⠀⠀⠀⠀⠄⠀⠀⠀⠀⠀⠳⣄⡀⠀⠀⠀⠀⠀⣠⠏⢡⢀⠒⠄⠢⠀⠀⢈${B_PINK}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷${B_PURPLE}⠀⠒⠰⢀⠊⡉⠤⠀⠺⢶⡀⠅⢂${B_PINK}⣵⡾⠋${B_PURPLE}⢀⠤⢠⣐⠢⣀⡠⠔⠒⠒⠢⣀⠠⠀⠄⠐⠂⠀⠈⠀⠀⠀⡀⠀⠀⠀⠀⠆⡨⠄⠃⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⡀⠀⠀⠀⠀⠂⠀⠀⠀⠀⠀⠀⠀⠁⠤⢀⡤⠚⡍⠀⠨⠄⣀⣤⣶⣶⣶⣶${B_PINK}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏${B_PURPLE}⢭⡁⣄⠈⠻⣿⠇⣠⠘⡀⠀⠐⠈⡀⠂⣀⣤${B_PINK}⣾⡿⡋${B_PURPLE}⢀⢳⠌⣀⢃⠰⠌⣩⠐⠂⡉⠉⠒⡀⠑⠀⠈⠀⠐⠀⠀⠀⠄⡠⠀⠄⠀⡁⠔⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⢌⠀⠐⠀⠀⡁⠀⠀⠀⠀⠀⠀⠀⠀⠐⠚⠀⠆⠐⠂⠐⠀⢻${B_PINK}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢺⡥⣓${B_PURPLE}⠄⠢⡅⠹⡻⡟⠠⠄⠅⠒⣠⣴${B_PINK}⢾⣯⠗${B_PURPLE}⠋⣀⠉⢠⠞⣌⠢⡨⠗⢘⡁⢈⢁⡠⢁⠀⠀⠁⠀⠀⢀⡀⠈⠁⠈⣀⠑⠈⡌⠁⠆⣈⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⠢⠀⠀⠀⠀⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⣶⣶⣶⣶${B_PINK}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡷⣯⣷⣔${B_PURPLE}⣈⡄⣑⣭⡶⣤${B_PINK}⣾⣻⠽⠞⠉${B_PURPLE}⠀⠉⢀⢀⠰⢉⠶⠌⡖⠁⠤⠈⣤⠆⠁⡀⠳⠈⠀⡁⠠⠈⠠⢀⠀⠔⠀⠀⠀⠀⢀⠉⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⡑⠀⠀⠄⠀⡀⠐⠀⠀⠀⠸⣶⡆⠀⠀⢀⣤${B_PINK}⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢏⡿⠶⣝⣳⣿⣷⡟⠉${B_PURPLE}⢀⠘⢯⠀⠐⠀⠀⠀⡃⢁⠘⢀⣾⠐⡪⠈⢒⠄⠄⠢⣈⡘⠁⠂⠌⡀⠀⠂⠴⠀⢠⠒⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⠌⠀⠀⠀⠀⠄⠀⠄⠀⠉⠀⠀⠃⠐⠀⠀⠘${B_PINK}⣿⣿⣿⣿⣿⣿⣿⡿⣹⢿⣿⣿⣿⣿⣿⣿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣿⣾⡿⢻⡏${B_PURPLE}⢩⢛⣷⡀⠈⠒⣻⡀⠁⣀⠀⠀⡂⡁⠀⠘⡟⠁⠡⢩⢀⠋⢀⡁⡈⠘⠌⠇⠀⠐⠀⠐⠈⢂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠀⠀⠈⠀⠀⠀⠆⠀⠐⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_VIOLET}⠨⠀⢀⠀⠈⠀⠂⠀⠀⠂⠀⠠⠁⠀⠠⡈⠀⠘${B_PINK}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢏⣽⣿⣿⣿⡿⠂${B_VIOLET}⠙⢦⡘⢻⣽⣶${B_PINK}⣿⣿⣷${B_VIOLET}⡀⠠⠀⢂⠈⢁⣠⣌⢱⡄⢐⠣⡈⠄${B_PINK}⣵⡀${B_VIOLET}⡈⠔⠐⠄⠁⠀⠄⠠⠁⠂⠀⠀⠀⢀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_VIOLET}⡳⠀⢀⠆⠘⡄⠀⠀⡄⢀⠘⠀⠀⠀⠆⢠⣴⣤⠸${B_PINK}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⡇${B_VIOLET}⡄⠀⠀⠃⢷⣾${B_PINK}⣿⣿⣿⣿⣿⣿⣄${B_VIOLET}⠀⠆⠀⣰⢟⣀⠶⠀⣤⡀⢇${B_PINK}⣤⢿⡆${B_VIOLET}⡀${B_PINK}⣸⡄${B_VIOLET}⠀⡄⠀⢀⠰⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡄⠀⠀⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_VIOLET}⠱⠀⢨⠀⠀⠆⠀⠀⠆⢨⠀⠘⠀⠆⡴⠸${B_PINK}⣿⣵⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠟⠃${B_VIOLET}⢠⡅⣤⠃⠰⠀⠙${B_PINK}⣿⣿⣿⣿⣿⣿⣿⡆${B_VIOLET}⠘⠸⠃⠛⠟⠀⡟⢻${B_PINK}⣽⣿⠟${B_VIOLET}⠈⣤⢡${B_PINK}⡟${B_VIOLET}⠃⠀⡜⠰⠸⢧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠶⠀⠘⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠆⠀⠀⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⠈⢀⠠⠀⠈⠀⠒⠀⠀⠀⠀⠂⡃⠈⠔⠄⡩⢁⡙${B_PINK}⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠉${B_PURPLE}⣉⣲⠐⠄⠀⡄⢘⢈⠒⡨⢀⡘⠂⡀⢁⠀⠹${B_PINK}⣿⣿⣿⣿⣿⣷${B_PURPLE}⡁⠰⣆⠀⠀⠩⢉⢁⢘⠛⠊⡁⠈⠈⠅⢈⢃⠀⠐⠰⠸⡓⢲⡀⠀⠀⠀⠀⠀⢀⠐⠁⠈⡀⢂⠀⡠⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⠈⠀⡀⠐⠀⢁⣀⠀⡀⢈⠀⠀⠤⠉⠄⠣⠜⢨⡐⢀⢻${B_PINK}⣿⣿⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠁${B_PURPLE}⠰⠸⠂⠡⣨⢃⠐⠆⣂⢡⠐⡄⠩⠜⡰⢀⠌⡅⢈⠻${B_PINK}⣿⣿⣿⣿⣷${B_PURPLE}⡀⠤⠤⠀⢂⠠⠄⡀⢡⠈${B_PINK}⣀⣾⠃${B_PURPLE}⠀⣟⢈⠀⢡⢈⡁⢣⠀⢇⠀⠀⠀⠀⢀⠀⡀⢈⡐⠀⠄⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⠀⠀⢀⠔⢉⠔⢀⠒⠤⢀⠡⠄⢃⠪⠌⡡⢚⢠⣈⠄${B_PINK}⣾⣿⣿⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏${B_PURPLE}⠄⠐⢀⠑⡄⢊⡀⢓⡶⢯⠐⠒⠀⠤⠠⣌⠉⠦⠰⡀⢦⡈⠔⢢⠘⢻${B_PINK}⣿⣿⣿⣷${B_PURPLE}⡀⠐⠐⠂⠄⢂⠀${B_PINK}⠴⣶⠋${B_PURPLE}⣁⢈⠀${B_PINK}⣸⢎${B_PURPLE}⠠${B_PINK}⣿⡖${B_PURPLE}⢼⡅⢳⡀⢀⠀⠀⠀⡈⠀⠠⠜⠇⠈⠠⠀⡀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PURPLE}⠀⡀⠤⠘⢠⠊⢀⠊⡐⠂⠙⠄⠦⡁⠒⠰⠀⠄⡑⢸${B_PINK}⣿⣿⣷⣤⡙⠼⢭⢩⠵⣍⠟⣭⣻⣿⣿⡿${B_PURPLE}⣠⠐⡈⢄⣧⢹⡀⠂⣈⡙⠀⡨⠑⡍⡒⠡⢄⠙⡇⡑⢢⠐⠡⡘⢈⠢⢁⠹${B_PINK}⣿⣿⣿⣷⣄${B_PURPLE}⡀⠀⠁⠀⠄⠀⢏⣉⢻${B_PINK}⣹⡆${B_PURPLE}⣬${B_PINK}⣷⣦${B_PURPLE}⢏⢻${B_PINK}⡌⠾⣾⡇${B_PURPLE}⡀⢀⠀⠁⠀⠀⢁⠄⢀⡂⠁⣀⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_PINK}⠉⠀⢄⠉⡂⠌⢢⠀⢂⠌⠁⡌⠠⢐⠉⠠⠉⢡⠀⠀${B_PINK}⢿⣿⣿⣿⣿⣿⣶⣧⣾⣴⣯⣾⣿⣿⠏${B_PINK}⣠⣿⢷⣈⡼⠿⡁⢣⢁⣬⡁⡖⢁⠲⠇⡐⢃⣼⡇⢰⠠⠡⢌⡑⢠⠈⠩⠑⢄⠈${B_PINK}⣿⣿⣿⣿⣦${B_PURPLE}⡢⢀⠂⠉⠷${B_PINK}⣽⣿⣰⣮${B_PURPLE}⡹${B_PINK}⣦${B_PURPLE}⠘${B_PINK}⢷⣯⣰⣿⡄${B_PURPLE}⢻${B_PINK}⢷⢻${B_PURPLE}⠀⣧⠀⢀⠀⠀⡀⠄⠀⠄⡈⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_CYAN}⠀⠈⡄⠠⢉⠔⡠⠜⠠⢌⠂⠤⢁⠄⠂⡁⠡⠀⠀⠀⠀⡇⣬⢛⠻⠿${B_PINK}⣿⣿⣿⡿⣿⣷⡿${B_CYAN}⡟⣶⣹⢏${B_PINK}⣼⣿${B_CYAN}⢃⡒⡒⢯⢠⢑⡀⠜⡤⣨⣁⠆⢟⡁⢺⠻⡀⠇⠤⠐⠄⠂⠅⠣⠐⠆⡈${B_PINK}⢿⣿⣿⣿⣿⡂${B_CYAN}⠠⣀⢴⣖⢹⠽⠋${B_PINK}⢿⣇⣷⡞${B_CYAN}⢿⣳⠌⠹⠆⡈⢸⡜⢙⠀⠈⠀⠀⠙⢁⠀⣤⠀⢌⠢⣀⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_CYAN}⠀⠂⡄⢁⠢⠁⠴⠈⠖⠢⠌⠴⠠⠐⠦⠐⠀⠒⠀⠂⢸⢃⠣⣌⡃⡒⠐⣠${B_PINK}⣿⣿⣿⣟⣻⣯⣭⢊⣻⣯⣦${B_CYAN}⠒⢇⡑⢺⡤⢦⣅⡎⣜⡳⡉⡷⢷⡿⢃⣒⣃⣒⣒⣁⣊⣑⢂⡒⣈⢄⡠⢙${B_PINK}⣿⣿⣿⣿⣷⣜⢿⠿⣿⠆${B_CYAN}⣀⢊⢡${B_PINK}⣿⣾⣿${B_CYAN}⢜⣫⠉${B_PINK}⣼⣮⣿⡈${B_CYAN}⠹⢾⡄⢁⢀⡀⣀⠀${B_PINK}⣶⣧⣧${B_CYAN}⡈⠐⠀⠇⢀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_CYAN}⣀⣀⣀⣀⣈⣉⣈⣩⣥⣦⣤⢦⢭⣤⢭⣉⣏⡭⣭⣡⣬⣧⣓⡌⡃⢌⣰${B_PINK}⣿⡿⠿⢿⣺⣿⣯⣿⣧⣼⡿${B_CYAN}⣝⡟⣈⣤⢋⠗⣠⣤⡴⣼⠷⣯⢿⠧⡞⣧⢥⢦⡴⣌⣰⢤⡬⠄⣁⡠⠂⠂⢉${B_PINK}⣿⣿⣿⣿⣿⣿⣆${B_CYAN}⡯⡽⠛⣁⠤⢤⢽⠾⣿⣯⣿⣿⣿⣿⡛⡏⠷⣽⠃⡒⠀⠀⡀⠰⡼⠿⠿⠿⠿⠶⣦⠤⠀⢀⠠⠈⠀⠁⠄⠠⠀⠄⠀⠀⠀⠄⠀⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${B_CYAN}⢉⢐⣢⣭⣫⣛⣛⣭⣭⣽⡼⡭⠾⠤⠷⠼⣴⣎⣳⢛⡼⠮⠿⢟⡛⢟⡳⠶⠿⣿⡿⠿⠻⠿⠷⡿⢻⡿⣧⠾⠿⣐⠭⠧⠷⢆⡓⠮⡝⣬⣩⣚⠱⣌⣋⡭⣖⡥⣞⣤⣭⡽⣤⢦⡵⣶⣮${B_PINK}⣿⣿⣿⣿⣿⣿⣿⠾${B_CYAN}⠝⠛⠃⢋⣉⣩${B_PINK}⣿⣿⣿⣿⣿⣿⡏⣿${B_CYAN}⣥⣶⣡⣷⢶⣶⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣀⣈⡀⣀⣀⣀⣀⣀⣀⣀⡀⣀⠀⣀⢀⡀⣁⢀⡀⢈⡀⣁⡀⣀⡀⠐⠀⠂⠀⠂⠀⠀⠀"
    echo -e "${B_TEAL}⠸⠉⢵⣶⣽⠄⢃⠢⢴⣄⣐⣢⣡⣉⣜⣠⣆⠰⠌⠥⢲⣉⣱⢨⡐⠡⠦⠙⠒⠠⠦⠭⠭⠴⠣⠼⠔⣒⠒⢓⣒⠓⡨⢉⣍⣆⣜⠭⠵⠦⠧⠭⠿⠐⠮⣉⣰⢈⠩⡡⢍⡱⠭⢭⠓⡳⠮⠽⠯⠘⡙⢉⣉⣀⣀⣌⡙⢫⠝⣻⣻⢟⡿⣛⣿⡻⢯⣽⣯⣷⣚⣻⣷⣚⣶⣾⠶⠷⢬⣍⠡⠦⠖⠒⢈⣀⣉⣉⣉⣉⣉⣉⣉⡉⢉⠉⡁⠀⠀⠉⠀⠉⠈⠀⠉⠀⠁⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂⠈⠀"
    echo -e "${B_TEAL}⠀⠀⢛⡏⠁⠀⠂⠄⠂⠀⠄⠀⠐⠂⠒⠀⡀⠄⠤⠄⠠⠀⠰⠤⢀⢂⠐⠠⠁⠦⠐⠃⠚⠑⠐⠒⠒⠤⠭⠒⠠⠭⠑⠒⠒⠒⠒⠒⠒⠒⠓⢉⠈⡁⠀⠀⠤⡉⠑⠒⠛⠉⣉⠒⠒⠒⠒⠓⠒⠈⠉⠀⠀⠀⠀⠀⠙⠋⠛⠉⠉⠋⠙⠚⠒⠛⠛⠒⠢⠤⠧⠖⠒⠒⠒⠈⡉⠈⠀⠀⠀⠀⠀⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo -e "${C_RESET}"
}

render_cosmos_cli_animation() {
    tput civis 2>/dev/null || printf "\033[?25l"

    local -a lines=(
        "   __________  _____ __  _______  _____   ________    ____"
        "  / ____/ __ \\/ ___//  |/  / __ \\/ ___/  / ____/ /   /  _/"
        " / /   / / / /\\__ \\/ /|_/ / / / /\\__ \\  / /   / /    / /  "
        "/ /___/ /_/ /___/ / /  / / /_/ /___/ / / /___/ /____/ /   "
        "\\____/\\____//____/_/  /_/\\____//____/  \\____/_____/___/   "
    )

    for ((step = 0; step < 12; step++)); do
        for ((i = 0; i < ${#lines[@]}; i++)); do
            local line="${lines[$i]}"
            local len=${#line}
            for ((j = 0; j < len; j++)); do
                local char="${line:$j:1}"
                if [[ "$char" == " " ]]; then
                    printf " "
                else
                    local phase=$(( (step * 24 + j * 7 + i * 14) % 360 ))
                    local r=$(( 128 + 127 * (phase < 180 ? (phase < 60 ? phase * 4 : (phase < 120 ? 255 : (180 - phase) * 4)) : 0) / 255 ))
                    local g=$(( 128 + 127 * (phase >= 60 && phase < 240 ? (phase < 120 ? (phase - 60) * 4 : (phase < 180 ? 255 : (240 - phase) * 4)) : 0) / 255 ))
                    local b=$(( 128 + 127 * (phase >= 180 ? (phase < 240 ? (phase - 180) * 4 : (phase < 300 ? 255 : (360 - phase) * 4)) : 0) / 255 ))
                    printf "\033[38;2;%d;%d;%dm%s" "$r" "$g" "$b" "$char"
                fi
            done
            printf "%b\n" "${C_RESET}"
        done
        sleep 0.03
        if (( step < 11 )); then
            printf "\033[5A"
        fi
    done

    tput cnorm 2>/dev/null || printf "\033[?25h"
}

render_cosmos_cli_static() {
    local -a lines=(
        "   __________  _____ __  _______  _____   ________    ____"
        "  / ____/ __ \\/ ___//  |/  / __ \\/ ___/  / ____/ /   /  _/"
        " / /   / / / /\\__ \\/ /|_/ / / / /\\__ \\  / /   / /    / /  "
        "/ /___/ /_/ /___/ / /  / / /_/ /___/ / / /___/ /____/ /   "
        "\\____/\\____//____/_/  /_/\\____//____/  \\____/_____/___/   "
    )

    for ((i = 0; i < ${#lines[@]}; i++)); do
        local line="${lines[$i]}"
        local len=${#line}
        for ((j = 0; j < len; j++)); do
            local char="${line:$j:1}"
            if [[ "$char" == " " ]]; then
                printf " "
            else
                local phase=$(( (j * 7 + i * 14) % 360 ))
                local r=$(( 128 + 127 * (phase < 180 ? (phase < 60 ? phase * 4 : (phase < 120 ? 255 : (180 - phase) * 4)) : 0) / 255 ))
                local g=$(( 128 + 127 * (phase >= 60 && phase < 240 ? (phase < 120 ? (phase - 60) * 4 : (phase < 180 ? 255 : (240 - phase) * 4)) : 0) / 255 ))
                local b=$(( 128 + 127 * (phase >= 180 ? (phase < 240 ? (phase - 180) * 4 : (phase < 300 ? 255 : (360 - phase) * 4)) : 0) / 255 ))
                printf "\033[38;2;%d;%d;%dm%s" "$r" "$g" "$b" "$char"
            fi
        done
        printf "%b\n" "${C_RESET}"
    done
}

render_status_bar() {
    echo -e "  ${C_PURPLE}* ${C_BOLD}Cosmos Rice Deployment Suite${C_RESET} ${C_DIM}| Modular System Pipeline${C_RESET}"
    echo -e "  ${C_BLUE}* Target System:${C_RESET} ${C_YELLOW}${DISTRO^^}${C_RESET}"
    echo -e "  ${C_DARK}─────────────────────────────────────────────────────────────────────────────${C_RESET}\n"
}

print_banner() {
    clear
    render_character_art
    render_cosmos_cli_static
    render_status_bar
}

select_distro() {
    print_banner
    echo -e "  ${C_BOLD}Select Target Distribution / Package Manager:${C_RESET}\n"
    echo -e "  ${C_CYAN}[1]${C_RESET} Arch Linux   ${C_DIM}(pacman / yay / paru)${C_RESET}"
    echo -e "  ${C_CYAN}[2]${C_RESET} NixOS / Nix  ${C_DIM}(nix flakes / nixpkgs)${C_RESET}"
    echo -e "  ${C_DARK}─────────────────────────────────────────────────────────────────────────────${C_RESET}"
    
    read -rp "  Select option [1-2]: " d_choice || d_choice=""
    case "$d_choice" in
        1)
            export DISTRO="arch"
            echo -e "  ${C_GREEN}-> Target set to Arch Linux.${C_RESET}"
            sleep 1
            ;;
        2)
            export DISTRO="nix"
            echo -e "  ${C_GREEN}-> Target set to NixOS / Nix.${C_RESET}"
            sleep 1
            ;;
        *)
            echo -e "  ${C_RED}-> Invalid selection. Retaining current: ${DISTRO}${C_RESET}"
            sleep 1
            ;;
    esac
}

run_stage() {
    local script_name="$1"
    local stage_title="$2"

    echo -e "\n  ${C_BLUE}╭─[STAGE]${C_RESET} ${C_BOLD}${stage_title}${C_RESET}"
    echo -e "  ${C_BLUE}│${C_RESET} Target OS: ${C_YELLOW}${DISTRO^^}${C_RESET}"

    if [ -f "$SCRIPT_DIR/$script_name" ]; then
        if bash "$SCRIPT_DIR/$script_name"; then
            echo -e "  ${C_BLUE}│${C_RESET}"
            echo -e "  ${C_GREEN}╰─[OK] ${stage_title} finished successfully.${C_RESET}\n"
        else
            echo -e "  ${C_BLUE}│${C_RESET}"
            echo -e "  ${C_RED}╰─[ERR] ${stage_title} encountered an error.${C_RESET}\n"
            read -rp "  Press [Enter] to continue..." || true
        fi
    else
        echo -e "  ${C_RED}╰─[ERR] Script not found: $script_name${C_RESET}\n"
        read -rp "  Press [Enter] to continue..." || true
    fi
}

run_all() {
    print_banner
    echo -e "  ${C_YELLOW}* Starting Full Automated Pipeline for ${DISTRO^^}...${C_RESET}\n"

    run_stage "download.sh"        "1/5: Downloading Packages & Assets"
    run_stage "install.sh"         "2/5: Installing System Themes & Shell"
    run_stage "SrodKitty.sh"       "3/5: Deploying Kitty Terminal Configuration"
    run_stage "setShell.sh"        "4/5: Configuring Shell & Dynamic ASCII Art"
    run_stage "syncWallpapers.sh"  "5/5: Deploying Wallpapers (Structured)"

    echo -e "  ${C_DARK}─────────────────────────────────────────────────────────────────────────────${C_RESET}"
    echo -e "  ${C_GREEN}${C_BOLD}[OK] Cosmos Rice deployment completed.${C_RESET}"
    echo -e "  ${C_CYAN}-> Reload current shell via: ${C_YELLOW}exec \$SHELL${C_RESET}\n"
    read -rp "  Press [Enter] to exit..." || true
    exit 0
}

# --- Initial Launch ---
clear
render_character_art
render_cosmos_cli_animation
render_status_bar

# --- Menu Loop ---
while true; do
    echo -e "  ${C_BOLD}Select an operation:${C_RESET}\n"
    echo -e "  ${C_CYAN}[1]${C_RESET} Run Full Pipeline              ${C_DIM}(Execute all 5 stages sequentially)${C_RESET}"
    echo -e "  ${C_CYAN}[2]${C_RESET} Switch Target OS (${DISTRO^^})       ${C_DIM}(Toggle between Arch and NixOS)${C_RESET}"
    echo -e "  ${C_CYAN}[3]${C_RESET} Download Assets                ${C_DIM}(download.sh - Git, Kitty, Fastfetch, Themes)${C_RESET}"
    echo -e "  ${C_CYAN}[4]${C_RESET} Install Themes & Shell         ${C_DIM}(install.sh - Caelestia, SDDM, GRUB)${C_RESET}"
    echo -e "  ${C_CYAN}[5]${C_RESET} Deploy Kitty Terminal Config   ${C_DIM}(SrodKitty.sh - Dotfile Sync & Backups)${C_RESET}"
    echo -e "  ${C_CYAN}[6]${C_RESET} Configure ASCII Art & Shell    ${C_DIM}(setShell.sh - Fastfetch Banner Injection)${C_RESET}"
    echo -e "  ${C_CYAN}[7]${C_RESET} Sync Wallpapers (Structured)   ${C_DIM}(syncWallpapers.sh - Deploy hierarchy to ~/Pictures/Wallpapers)${C_RESET}"
    echo -e "  ${C_DARK}─────────────────────────────────────────────────────────────────────────────${C_RESET}"
    echo -e "  ${C_RED}[0]${C_RESET} Exit\n"

    read -rp "  Enter choice [0-7]: " choice || choice="0"

    case "$choice" in
        1) run_all ;;
        2) select_distro ;;
        3) print_banner; run_stage "download.sh" "Downloading Packages & Assets"; read -rp "  Press [Enter] to return..." || true; print_banner ;;
        4) print_banner; run_stage "install.sh" "Installing System Themes & Shell"; read -rp "  Press [Enter] to return..." || true; print_banner ;;
        5) print_banner; run_stage "SrodKitty.sh" "Deploying Kitty Terminal Configuration"; read -rp "  Press [Enter] to return..." || true; print_banner ;;
        6) print_banner; run_stage "setShell.sh" "Configuring Shell & Dynamic ASCII Art"; read -rp "  Press [Enter] to return..." || true; print_banner ;;
        7) print_banner; run_stage "syncWallpapers.sh" "Deploying Wallpapers (Structured)"; read -rp "  Press [Enter] to return..." || true; print_banner ;;
        0) echo -e "\n  ${C_DIM}Exiting Cosmos Rice installer.${C_RESET}\n"; exit 0 ;;
        *) echo -e "\n  ${C_RED}[!] Invalid option selected.${C_RESET}"; sleep 1; print_banner ;;
    esac
done