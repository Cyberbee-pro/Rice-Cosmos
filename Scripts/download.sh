#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Asset & Package Downloader
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
            *arch*|*endeavouros*|*manjaro*|*garuda*|*artix*) echo "arch" ;;
            *nixos*|*nix*) echo "nix" ;;
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

DISTRO="${DISTRO:-$(detect_distro)}"
DOWNLOAD_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/cosmos/downloads"
mkdir -p "$DOWNLOAD_CACHE"

echo -e "${CYAN} Checking and installing core packages for ${DISTRO^^} . . . . ${NC}"

install_package() {
    local bin_name="$1"
    local nix_pkg="$2"
    local arch_pkg="$3"

    if command -v "$bin_name" &> /dev/null; then
        local ver
        ver="$("$bin_name" --version 2>&1 | head -n 1 || true)"
        echo -e "${GREEN}[OK] ${bin_name} is installed: ${ver}${NC}"
    else
        echo -e "${YELLOW}[..] ${bin_name} not found. Installing for ${DISTRO^^}...${NC}"
        if [ "$DISTRO" = "nix" ]; then
            if ! command -v nix &>/dev/null; then
                echo -e "${RED}[ERR] 'nix' package manager not found.${NC}"
                exit 1
            fi
            echo -e "${YELLOW}[i] NixOS detected: installing imperatively via nix profile. (Declarative configuration in configuration.nix is recommended).${NC}"
            nix --extra-experimental-features 'nix-command flakes' profile install "nixpkgs#${nix_pkg}"
        else
            if ! command -v pacman &>/dev/null; then
                echo -e "${RED}[ERR] 'pacman' package manager not found.${NC}"
                exit 1
            fi
            if [ "$EUID" -eq 0 ]; then
                pacman -Sy --needed --noconfirm "$arch_pkg"
            elif command -v sudo &>/dev/null; then
                sudo pacman -Sy --needed --noconfirm "$arch_pkg"
            else
                echo -e "${RED}[ERR] Root privileges or sudo required to install ${arch_pkg}.${NC}"
                exit 1
            fi
        fi

        if command -v "$bin_name" &> /dev/null; then
            echo -e "${GREEN}[OK] ${bin_name} installed successfully.${NC}"
        else
            echo -e "${RED}[ERR] Failed to install ${bin_name}.${NC}"
            exit 1
        fi
    fi
}

install_package "git" "git" "git"
install_package "kitty" "kitty" "kitty"
install_package "fastfetch" "fastfetch" "fastfetch"

sync_repo() {
    local repo_url="$1"
    local target_dir="$2"
    local name="$3"

    echo -e "${CYAN}[..] Syncing ${name} . . . .${NC}"
    if [ -d "$target_dir/.git" ]; then
        echo -e "${YELLOW}Updating ${name}...${NC}"
        git -C "$target_dir" pull --ff-only || {
            echo -e "${RED}Fast-forward failed. Re-cloning ${name}...${NC}"
            rm -rf "$target_dir"
            git clone "$repo_url" "$target_dir"
        }
    else
        rm -rf "$target_dir"
        git clone "$repo_url" "$target_dir"
    fi
    echo -e "${GREEN}[OK] ${name} ready at ${target_dir}.${NC}"
}

if [ "$DISTRO" = "arch" ]; then
    sync_repo "https://github.com/adnksharp/CyberGRUB-2077" "$DOWNLOAD_CACHE/CyberGRUB-2077" "CyberGRUB-2077"
    sync_repo "https://github.com/Darkkal44/qylock" "$DOWNLOAD_CACHE/qylock" "QYLock SDDM"
else
    echo -e "${YELLOW}[!] NixOS manages system themes declaratively. Skipping mutable theme downloads.${NC}"
fi