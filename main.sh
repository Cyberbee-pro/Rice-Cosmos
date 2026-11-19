#!/usr/bin/env bash

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    echo -e "\033[0;31m[ERR] Please do not run this script as root or with sudo.\033[0m" >&2
    echo -e "\033[0;33m[!] Run as your regular desktop user. Elevation (sudo) will be prompted automatically if packages need to be installed.\033[0m" >&2
    exit 1
fi

# ==============================================================================
#  COSMO CLI : Master Orchestrator (Arch Linux & NixOS)
# ==============================================================================

set -euo pipefail

# Script Directory Resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure all companion scripts are executable
find "$SCRIPT_DIR/Scripts" -name "*.sh" -exec chmod +x {} + 2>/dev/null || true

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
    echo -e "${B_PINK}⠢⠀⠀⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠀⠀⣸⣿⣀⡀⠐⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⣿⡟⢻⣿⣿⣿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠉⠈⠈⠁⠈⠁⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
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

render_cosmo_cli_static() {
    local -a lines=(
        "   __________  _____ __  _______    ________    ____ "
        "  / ____/ __ \\/ ___//  |/  / __ \\  / ____/ /   /  _/ "
        " / /   / / / /\\__ \\/ /|_/ / / / /  / /   / /    / /  "
        "/ /___/ /_/ /___/ / /  / / /_/ /  / /___/ /____/ /   "
        "\\____/\\____//____/_/  /_/\\____/  \\____/_____/___/   "
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
    echo -e "  ${C_PURPLE}* ${C_BOLD}Cosmo CLI Deployment Suite${C_RESET} ${C_DIM}| Dual-Distro Architecture (Arch Linux & NixOS)${C_RESET}"
    echo -e "  ${C_BLUE}* Target System:${C_RESET} ${C_YELLOW}${DISTRO^^} (Caelestia Shell + Hyprland Lua)${C_RESET}"
    echo -e "  ${C_DARK}─────────────────────────────────────────────────────────────────────────────${C_RESET}\n"
}

print_banner() {
    clear
    render_character_art
    render_cosmo_cli_static
    render_status_bar
}

select_distro() {
    print_banner
    echo -e "  ${C_BOLD}Select Target Operating System:${C_RESET}\n"
    echo -e "  ${C_CYAN}[1]${C_RESET} Arch Linux    ${C_DIM}(pacman, AUR yay/paru, CyberGRUB, SDDM)${C_RESET}"
    echo -e "  ${C_CYAN}[2]${C_RESET} NixOS         ${C_DIM}(nixos-rebuild, Flakes, Declarative themes)${C_RESET}"
    echo -e "  ${C_DARK}─────────────────────────────────────────────────────────────────────────────${C_RESET}"
    read -rp "  Enter choice [1-2, default: ${DISTRO}]: " d_choice || d_choice=""
    case "$d_choice" in
        1) DISTRO="arch"; export DISTRO ;;
        2) DISTRO="nixos"; export DISTRO ;;
        *) ;;
    esac
}

run_stage() {
    local script_name="$1"
    local stage_title="$2"

    echo -e "\n  ${C_BLUE}╭─[STAGE]${C_RESET} ${C_BOLD}${stage_title}${C_RESET}"
    echo -e "  ${C_BLUE}│${C_RESET} Target OS: ${C_YELLOW}${DISTRO^^}${C_RESET}"

    local script_path=""
    if [ -f "$SCRIPT_DIR/Scripts/$script_name" ]; then
        script_path="$SCRIPT_DIR/Scripts/$script_name"
    elif [ -f "$SCRIPT_DIR/$script_name" ]; then
        script_path="$SCRIPT_DIR/$script_name"
    fi

    if [ -n "$script_path" ]; then
        if bash "$script_path"; then
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
    if [ "$DISTRO" = "arch" ]; then
        run_stage "install.sh"     "2/5: Installing System Themes & SDDM"
    else
        run_stage "install.sh"     "2/5: Deploying NixOS Flake & Caelestia Shell"
    fi
    run_stage "SrodKitty.sh"       "3/5: Deploying Dotfiles & Helper Binaries"
    run_stage "setShell.sh"        "4/5: Configuring Shells (Bash & Zsh)"
    run_stage "syncWallpapers.sh"  "5/5: Deploying Wallpapers (Structured)"

    echo -e "  ${C_DARK}─────────────────────────────────────────────────────────────────────────────${C_RESET}"
    echo -e "  ${C_GREEN}${C_BOLD}[OK] Cosmo CLI deployment completed for ${DISTRO^^}.${C_RESET}"
    echo -e "  ${C_CYAN}-> Reload current shell via: ${C_YELLOW}exec \$SHELL${C_RESET}\n"
    read -rp "  Press [Enter] to exit..." || true
    exit 0
}

run_terminal_only() {
    print_banner
    echo -e "  ${C_YELLOW}* Starting Terminal-Only Setup (Bash + Kitty) for ${DISTRO^^}...${C_RESET}\n"

    run_stage "setup-bash.sh"  "1/2: Configuring Standalone Bash & Cosmo Banner"
    run_stage "setup-kitty.sh" "2/2: Deploying Standalone Kitty Terminal"

    echo -e "  ${C_DARK}─────────────────────────────────────────────────────────────────────────────${C_RESET}"
    echo -e "  ${C_GREEN}${C_BOLD}[OK] Terminal-Only setup completed.${C_RESET}"
    echo -e "  ${C_CYAN}-> Reload current shell via: ${C_YELLOW}exec bash${C_RESET}\n"
    read -rp "  Press [Enter] to return..." || true
}

run_modular_menu() {
    while true; do
        print_banner
        echo -e "  ${C_BOLD}Select an Individual Component to Set Up (${DISTRO^^}):${C_RESET}\n"
        echo -e "  ${C_CYAN}[1]${C_RESET} Bash Shell             ${C_DIM}(setup-bash.sh - Banner, Starship & Aliases)${C_RESET}"
        echo -e "  ${C_CYAN}[2]${C_RESET} Kitty Terminal         ${C_DIM}(setup-kitty.sh - Standalone Kitty & Fonts)${C_RESET}"
        echo -e "  ${C_CYAN}[3]${C_RESET} Zsh Shell              ${C_DIM}(setup-zsh.sh - Banner, Starship & Aliases)${C_RESET}"
        echo -e "  ${C_CYAN}[4]${C_RESET} Starship Prompt        ${C_DIM}(setup-starship.sh - Starship Preset & TOML)${C_RESET}"
        echo -e "  ${C_CYAN}[5]${C_RESET} Fastfetch              ${C_DIM}(setup-fastfetch.sh - Fastfetch Spec & Logos)${C_RESET}"
        echo -e "  ${C_CYAN}[6]${C_RESET} Caelestia Shell        ${C_DIM}(setup-caelestia.sh - Caelestia Lua & Shell)${C_RESET}"
        echo -e "  ${C_CYAN}[7]${C_RESET} Hyprland Runtime       ${C_DIM}(setup-hypr.sh - Hyprland Ecosystem Packages)${C_RESET}"
        echo -e "  ${C_CYAN}[8]${C_RESET} Neovim Editor          ${C_DIM}(setup-nvim.sh - LazyVim / Custom Config)${C_RESET}"
        echo -e "  ${C_CYAN}[9]${C_RESET} Helper Binaries        ${C_DIM}(setup-bin.sh - toggle-hz, gamemode, opacity)${C_RESET}"
        echo -e "  ${C_CYAN}[10]${C_RESET} SDDM Display Manager  ${C_DIM}(setup-sddm.sh - QYLock & Nier Theme; Arch only)${C_RESET}"
        echo -e "  ${C_CYAN}[11]${C_RESET} Sync Wallpapers       ${C_DIM}(syncWallpapers.sh - Deploy hierarchy)${C_RESET}"
        echo -e "  ${C_CYAN}[12]${C_RESET} Harvest System Configs${C_DIM}(syncRepo.sh - Live Configs -> Repo)${C_RESET}"
        echo -e "  ${C_DARK}─────────────────────────────────────────────────────────────────────────────${C_RESET}"
        echo -e "  ${C_RED}[0]${C_RESET} Return to Main Menu\n"

        read -rp "  Select component [0-12]: " sub_choice || sub_choice="0"

        case "$sub_choice" in
            1)  print_banner; run_stage "setup-bash.sh" "Setting Up Standalone Bash"; read -rp "  Press [Enter] to return..." || true ;;
            2)  print_banner; run_stage "setup-kitty.sh" "Setting Up Standalone Kitty"; read -rp "  Press [Enter] to return..." || true ;;
            3)  print_banner; run_stage "setup-zsh.sh" "Setting Up Standalone Zsh"; read -rp "  Press [Enter] to return..." || true ;;
            4)  print_banner; run_stage "setup-starship.sh" "Setting Up Standalone Starship"; read -rp "  Press [Enter] to return..." || true ;;
            5)  print_banner; run_stage "setup-fastfetch.sh" "Setting Up Standalone Fastfetch"; read -rp "  Press [Enter] to return..." || true ;;
            6)  print_banner; run_stage "setup-caelestia.sh" "Setting Up Standalone Caelestia Shell"; read -rp "  Press [Enter] to return..." || true ;;
            7)  print_banner; run_stage "setup-hypr.sh" "Checking Hyprland Runtime Packages"; read -rp "  Press [Enter] to return..." || true ;;
            8)  print_banner; run_stage "setup-nvim.sh" "Setting Up Standalone Neovim"; read -rp "  Press [Enter] to return..." || true ;;
            9)  print_banner; run_stage "setup-bin.sh" "Deploying Helper Binaries"; read -rp "  Press [Enter] to return..." || true ;;
            10) print_banner; run_stage "setup-sddm.sh" "Setting Up SDDM & QYLock"; read -rp "  Press [Enter] to return..." || true ;;
            11) print_banner; run_stage "syncWallpapers.sh" "Deploying Wallpapers"; read -rp "  Press [Enter] to return..." || true ;;
            12) print_banner; run_stage "syncRepo.sh" "Harvesting Configurations"; read -rp "  Press [Enter] to return..." || true ;;
            0)  return 0 ;;
            *)  echo -e "\n  ${C_RED}[!] Invalid option selected.${C_RESET}"; sleep 1 ;;
        esac
    done
}

# --- Initial Launch ---
print_banner

# --- Main Menu Loop ---
while true; do
    echo -e "  ${C_BOLD}Select an operation:${C_RESET}\n"
    echo -e "  ${C_CYAN}[1]${C_RESET} Full Pipeline (${DISTRO^^})           ${C_DIM}(Execute all 5 stages sequentially)${C_RESET}"
    echo -e "  ${C_CYAN}[2]${C_RESET} Switch Target OS (${DISTRO^^})        ${C_DIM}(Toggle between Arch Linux and NixOS)${C_RESET}"
    echo -e "  ${C_CYAN}[3]${C_RESET} Terminal-Only Setup           ${C_DIM}(setup-bash.sh + setup-kitty.sh)${C_RESET}"
    echo -e "  ${C_CYAN}[4]${C_RESET} Modular Component Setups      ${C_DIM}(Select individual per-component setups)${C_RESET}"
    echo -e "  ${C_CYAN}[5]${C_RESET} Download Packages & Assets    ${C_DIM}(download.sh - Core packages, AUR helper & themes)${C_RESET}"
    echo -e "  ${C_CYAN}[6]${C_RESET} Install Themes / NixOS Flake  ${C_DIM}(install.sh - SDDM / CyberGRUB / /etc/nixos flake)${C_RESET}"
    echo -e "  ${C_CYAN}[7]${C_RESET} Deploy Dotfiles & Binaries    ${C_DIM}(SrodKitty.sh - Multi-app dotfile orchestration)${C_RESET}"
    echo -e "  ${C_CYAN}[8]${C_RESET} Configure Shells & Aliases    ${C_DIM}(setShell.sh - Bash & Zsh banner & aliases)${C_RESET}"
    echo -e "  ${C_CYAN}[9]${C_RESET} Sync Wallpapers (Structured)  ${C_DIM}(syncWallpapers.sh - Deploy hierarchy to Pictures)${C_RESET}"
    echo -e "  ${C_DARK}─────────────────────────────────────────────────────────────────────────────${C_RESET}"
    echo -e "  ${C_RED}[0]${C_RESET} Exit\n"

    read -rp "  Enter choice [0-9]: " choice || choice="0"

    case "$choice" in
        1) run_all ;;
        2) select_distro; print_banner ;;
        3) run_terminal_only; print_banner ;;
        4) run_modular_menu; print_banner ;;
        5) print_banner; run_stage "download.sh" "Downloading Packages & Assets"; read -rp "  Press [Enter] to return..." || true; print_banner ;;
        6) print_banner; run_stage "install.sh" "Installing Themes & Shell / NixOS Flake"; read -rp "  Press [Enter] to return..." || true; print_banner ;;
        7) print_banner; run_stage "SrodKitty.sh" "Deploying Dotfiles & Helper Binaries"; read -rp "  Press [Enter] to return..." || true; print_banner ;;
        8) print_banner; run_stage "setShell.sh" "Configuring Shells & Aliases"; read -rp "  Press [Enter] to return..." || true; print_banner ;;
        9) print_banner; run_stage "syncWallpapers.sh" "Deploying Wallpapers (Structured)"; read -rp "  Press [Enter] to return..." || true; print_banner ;;
        0) echo -e "\n  ${C_DIM}Exiting Cosmo CLI installer.${C_RESET}\n"; exit 0 ;;
        *) echo -e "\n  ${C_RED}[!] Invalid option selected.${C_RESET}"; sleep 1; print_banner ;;
    esac
done
