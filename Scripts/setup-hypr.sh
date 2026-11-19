#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Standalone Hyprland Runtime Packages Setup
# ==============================================================================

set -euo pipefail

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

echo -e "${CYAN}[..] Checking Hyprland Ecosystem Runtime Packages (${DISTRO^^}) . . . .${NC}"

if [ "$DISTRO" = "nixos" ]; then
    echo -e "${YELLOW}[i] NixOS manages Hyprland and portals declaratively (e.g. 'programs.hyprland.enable = true' in configuration.nix). Skipping pacman.${NC}"
    exit 0
fi

# Install required Arch Linux Hyprland runtime packages via pacman
HYPR_PKGS=(
    hyprland
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    polkit-gnome
    grim
    slurp
    wl-clipboard
    satty
    jq
    libnotify
)

missing_pkgs=()
for pkg in "${HYPR_PKGS[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        missing_pkgs+=("$pkg")
    fi
done

if [ ${#missing_pkgs[@]} -gt 0 ]; then
    echo -e "${YELLOW}[..] Installing missing packages via pacman: ${missing_pkgs[*]}...${NC}"
    if [ "$EUID" -eq 0 ]; then
        pacman -S --needed --noconfirm "${missing_pkgs[@]}"
    elif command -v sudo &>/dev/null; then
        sudo pacman -S --needed --noconfirm "${missing_pkgs[@]}"
    else
        echo -e "${RED}[ERR] Root privileges or sudo required to install: ${missing_pkgs[*]}${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}[OK] Hyprland ecosystem runtime packages verified successfully.${NC}"
