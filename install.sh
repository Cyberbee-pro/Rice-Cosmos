#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : System Theme & Shell Installer
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
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/Cosmos"
mkdir -p "$CONFIG_DIR"

# 1. Caelestia Shell via Nix Flakes
echo -e "${CYAN}[..] Running Caelestia Shell Setup . . . .${NC}"
if command -v nix &> /dev/null; then
    if nix --extra-experimental-features 'nix-command flakes' run github:caelestia-dots/shell; then
        echo -e "${GREEN}[OK] Caelestia Shell executed successfully.${NC}"
    else
        echo -e "${YELLOW}[!] Caelestia Shell execution failed or was skipped. Continuing...${NC}"
    fi
else
    echo -e "${YELLOW}[!] Nix binary not found. Skipping Caelestia Shell.${NC}"
fi

# 2. Distro-Gated System Theme Installation
if [ "$DISTRO" = "arch" ]; then
    RUN_AS_ROOT="sudo"
    if [ "$EUID" -eq 0 ]; then
        RUN_AS_ROOT=""
    elif ! command -v sudo &>/dev/null; then
        echo -e "${RED}[ERR] sudo command not found. Root privileges required.${NC}"
        exit 1
    fi

    # CyberGRUB-2077
    echo -e "${CYAN}[..] Installing CyberGRUB Theme (Arch Linux) . . . .${NC}"
    if [ -d "$DOWNLOAD_CACHE/CyberGRUB-2077" ]; then
        (
            cd "$DOWNLOAD_CACHE/CyberGRUB-2077"
            chmod +x install.sh 2>/dev/null || true
            $RUN_AS_ROOT bash ./install.sh -L arasaka
        )
        echo -e "${GREEN}[OK] CyberGRUB-2077 installed.${NC}"
    else
        echo -e "${RED}[ERR] CyberGRUB source not found in cache. Run download.sh first.${NC}"
        exit 1
    fi

    # QYLock SDDM Theme
    echo -e "${CYAN}[..] Installing QYLock SDDM Theme (Arch Linux) . . . .${NC}"
    if [ -d "$DOWNLOAD_CACHE/qylock" ]; then
        (
            cd "$DOWNLOAD_CACHE/qylock"
            chmod +x sddm.sh 2>/dev/null || true
            $RUN_AS_ROOT bash ./sddm.sh
        )
        echo -e "${GREEN}[OK] QYLock SDDM installed.${NC}"
    else
        echo -e "${RED}[ERR] QYLock source not found in cache. Run download.sh first.${NC}"
        exit 1
    fi
else
    # Declarative NixOS Generator
    echo -e "${CYAN}[..] Generating Declarative NixOS Module for Themes . . . .${NC}"
    cat << 'EOF' > "$CONFIG_DIR/nixos-theme-module.nix"
# Cosmos Rice - Declarative Theme Configuration for NixOS
{ pkgs, ... }:

{
  # 1. SDDM Configuration
  services.displayManager.sddm = {
    enable = true;
    theme = "qylock";
  };

  # 2. GRUB Configuration
  boot.loader.grub = {
    enable = true;
    # Custom GRUB theme packages can be referenced here
  };
}
EOF
    echo -e "${GREEN}[OK] Declarative NixOS module generated at: ${CONFIG_DIR}/nixos-theme-module.nix${NC}"
    echo -e "${YELLOW}-> Import this file in your /etc/nixos/configuration.nix to apply system themes.${NC}"
fi