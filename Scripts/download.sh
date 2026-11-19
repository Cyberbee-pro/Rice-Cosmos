#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Asset & Package Downloader (Arch Linux)
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

DOWNLOAD_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/cosmos/downloads"
mkdir -p "$DOWNLOAD_CACHE"

echo -e "${CYAN}[..] Checking and installing core packages for Arch Linux . . . .${NC}"

if ! command -v pacman &>/dev/null; then
    echo -e "${RED}[ERR] 'pacman' package manager not found. Arch Linux is required.${NC}"
    exit 1
fi

install_pkg() {
    local bin_name="$1"
    local arch_pkg="$2"

    if command -v "$bin_name" &> /dev/null; then
        local ver
        ver="$("$bin_name" --version 2>&1 | head -n 1 || true)"
        echo -e "${GREEN}[OK] ${bin_name} is installed: ${ver}${NC}"
    else
        echo -e "${YELLOW}[..] ${bin_name} not found. Installing via pacman...${NC}"
        if [ "$EUID" -eq 0 ]; then
            pacman -S --needed --noconfirm "$arch_pkg"
        elif command -v sudo &>/dev/null; then
            sudo pacman -S --needed --noconfirm "$arch_pkg"
        else
            echo -e "${RED}[ERR] Root privileges or sudo required to install ${arch_pkg}.${NC}"
            exit 1
        fi

        if command -v "$bin_name" &> /dev/null; then
            echo -e "${GREEN}[OK] ${bin_name} installed successfully.${NC}"
        else
            echo -e "${RED}[ERR] Failed to install ${bin_name}.${NC}"
            exit 1
        fi
    fi
}

install_pkg "git" "git"
install_pkg "kitty" "kitty"
install_pkg "fastfetch" "fastfetch"

sync_repo() {
    local repo_url="$1"
    local target_dir="$2"
    local name="$3"

    echo -e "${CYAN}[..] Syncing ${name} . . . .${NC}"
    if [ -d "$target_dir/.git" ]; then
        echo -e "${YELLOW}Updating ${name}...${NC}"
        git -C "$target_dir" pull --ff-only 2>/dev/null || {
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

echo -e "${CYAN}[..] Installing core Arch desktop packages . . . .${NC}"

ARCH_PKGS=(
    hyprland sddm qt6-svg qt6-declarative qt5-graphicaleffects
    qt5-quickcontrols2 qt5-svg grim slurp wl-clipboard satty
    starship zsh neovim base-devel xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk polkit-gnome pipewire pipewire-pulse
    wireplumber libnotify ttf-jetbrains-mono-nerd networkmanager jq
)

if [ "$EUID" -eq 0 ]; then
    pacman -S --needed --noconfirm "${ARCH_PKGS[@]}"
elif command -v sudo &>/dev/null; then
    sudo pacman -S --needed --noconfirm "${ARCH_PKGS[@]}"
else
    echo -e "${RED}[ERR] Root privileges or sudo required to install packages.${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] Core Arch desktop packages installed successfully.${NC}"

# Determine privilege wrapper for makepkg and AUR helper execution
if [ "$EUID" -eq 0 ]; then
    if [ -z "${SUDO_USER:-}" ] || [ "${SUDO_USER}" = "root" ]; then
        echo -e "${RED}[ERR] makepkg and AUR helpers cannot run as root, and no non-root SUDO_USER is available.${NC}"
        exit 1
    fi
    run_as_user() { sudo -u "$SUDO_USER" "$@"; }
else
    run_as_user() { "$@"; }
fi

# Detect existing AUR helper (paru or yay)
AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
fi

if [ -z "$AUR_HELPER" ]; then
    echo -e "${CYAN}[..] No AUR helper detected. Bootstrapping yay-bin . . . .${NC}"
    rm -rf /tmp/yay-bin
    run_as_user git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    (
        cd /tmp/yay-bin
        run_as_user makepkg -si --noconfirm
    )
    AUR_HELPER="yay"
    echo -e "${GREEN}[OK] yay-bin bootstrapped successfully.${NC}"
else
    echo -e "${GREEN}[OK] Detected existing AUR helper: ${AUR_HELPER}.${NC}"
fi

echo -e "${CYAN}[..] Installing Caelestia Shell and CLI via ${AUR_HELPER} . . . .${NC}"
run_as_user "$AUR_HELPER" -S --needed --noconfirm caelestia-shell caelestia-cli
echo -e "${GREEN}[OK] Caelestia Shell and CLI installed successfully.${NC}"

sync_repo "https://github.com/adnksharp/CyberGRUB-2077" "$DOWNLOAD_CACHE/CyberGRUB-2077" "CyberGRUB-2077"
sync_repo "https://github.com/Darkkal44/qylock" "$DOWNLOAD_CACHE/qylock" "QYLock SDDM"
