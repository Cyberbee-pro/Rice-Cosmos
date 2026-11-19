#!/usr/bin/env bash

# ==============================================================================
#  COSMO CLI : System Theme & Shell Installer (Arch Linux & NixOS)
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/nixos" ]; then
    REPO_ROOT="$SCRIPT_DIR"
elif [ -d "$SCRIPT_DIR/../nixos" ]; then
    REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    REPO_ROOT="$SCRIPT_DIR"
fi

DOWNLOAD_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/cosmos/downloads"

echo -e "${CYAN}[..] Running System Theme & Shell Installation (${DISTRO^^}) . . . .${NC}"

run_as_root() {
    if [ "$EUID" -eq 0 ]; then
        "$@"
    elif [ -d "${TARGET_ETC_DIR:-/etc/nixos}" ] && [ -w "${TARGET_ETC_DIR:-/etc/nixos}" ]; then
        "$@"
    elif [ ! -d "${TARGET_ETC_DIR:-/etc/nixos}" ] && [ -w "$(dirname "${TARGET_ETC_DIR:-/etc/nixos}")" ]; then
        "$@"
    elif command -v sudo &>/dev/null; then
        sudo "$@"
    else
        echo -e "${RED}[ERR] sudo command not found. Root privileges required.${NC}"
        exit 1
    fi
}

if [ "$DISTRO" = "arch" ]; then
    # 1. CyberGRUB-2077 (if present in download cache)
    if [ -d "$DOWNLOAD_CACHE/CyberGRUB-2077" ]; then
        echo -e "${CYAN}[..] Installing CyberGRUB Theme...${NC}"
        (
            cd "$DOWNLOAD_CACHE/CyberGRUB-2077"
            chmod +x install.sh 2>/dev/null || true
            run_as_root bash ./install.sh -L arasaka
        )
        echo -e "${GREEN}[OK] CyberGRUB-2077 installed.${NC}"
    else
        echo -e "${YELLOW}[!] CyberGRUB source not found in cache. Skipping GRUB theme.${NC}"
    fi

    # 2. SDDM & QYLock Theme
    bash "$SCRIPT_DIR/setup-sddm.sh"

    # 3. Caelestia Shell Setup
    bash "$SCRIPT_DIR/setup-caelestia.sh"

    echo -e "\n${GREEN}[OK] System themes & display manager installed successfully.${NC}"
else
    # -------------------------------------------------------------------------
    # Caelestia Shell via Nix Flakes (NixOS)
    # -------------------------------------------------------------------------
    echo -e "${CYAN}[..] Running Caelestia Shell Setup (NixOS) . . . .${NC}"
    if [ -z "${WAYLAND_DISPLAY:-}" ] && [ -z "${DISPLAY:-}" ]; then
        echo -e "${YELLOW}[!] No graphical display detected (WAYLAND_DISPLAY and DISPLAY unset). Skipping Caelestia Shell execution.${NC}"
    elif command -v nix &> /dev/null; then
        if nix --extra-experimental-features 'nix-command flakes' run github:caelestia-dots/shell; then
            echo -e "${GREEN}[OK] Caelestia Shell executed successfully.${NC}"
        else
            echo -e "${YELLOW}[!] Caelestia Shell execution failed or was skipped. Continuing...${NC}"
        fi
    else
        echo -e "${YELLOW}[!] Nix binary not found. Skipping Caelestia Shell.${NC}"
    fi

    # -------------------------------------------------------------------------
    # NixOS Flake & System Configuration Deployment
    # -------------------------------------------------------------------------
    TARGET_ETC_DIR="/etc/nixos"
    NIXOS_SRC="${REPO_ROOT}/nixos"

    if [ ! -d "$NIXOS_SRC" ]; then
        echo -e "${RED}[ERR] Source NixOS configuration directory not found at: ${NIXOS_SRC}${NC}"
        exit 1
    fi

    echo -e "\n${CYAN}=== NixOS Configuration & Flake Deployment ===${NC}"

    # 1. Back up existing /etc/nixos to /etc/nixos.backup_YYYYMMDD_HHMMSS
    BACKUP_ETC=""
    if [ -e "$TARGET_ETC_DIR" ] || [ -L "$TARGET_ETC_DIR" ]; then
        BACKUP_ETC="${TARGET_ETC_DIR}.backup_$(date +%Y%m%d_%H%M%S)"
        count=1
        while [ -e "$BACKUP_ETC" ] || [ -L "$BACKUP_ETC" ]; do
            BACKUP_ETC="${TARGET_ETC_DIR}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
            count=$((count + 1))
        done
        echo -e "${YELLOW}[..] Backing up existing ${TARGET_ETC_DIR} to ${BACKUP_ETC}...${NC}"
        run_as_root cp -a "$TARGET_ETC_DIR" "$BACKUP_ETC"
        echo -e "${GREEN}[OK] Backup created at ${BACKUP_ETC}.${NC}"
    fi

    run_as_root mkdir -p "$TARGET_ETC_DIR"

    # 2. Deploy ./nixos/ items
    echo -e "${CYAN}[..] Deploying NixOS configuration files to ${TARGET_ETC_DIR}...${NC}"
    for item in configuration.nix flake.nix flake.lock Scripts .gitignore; do
        if [ -e "$NIXOS_SRC/$item" ]; then
            run_as_root cp -rL --remove-destination "$NIXOS_SRC/$item" "$TARGET_ETC_DIR/"
            echo -e "${GREEN}[OK] Deployed ${item} to ${TARGET_ETC_DIR}/${item}.${NC}"
        else
            echo -e "${YELLOW}[!] Optional item ${item} not found in ${NIXOS_SRC}, skipping.${NC}"
        fi
    done

    # 3. Preserve target machine's existing hardware-configuration.nix from backup
    if [ -n "$BACKUP_ETC" ] && [ -f "$BACKUP_ETC/hardware-configuration.nix" ]; then
        echo -e "${CYAN}[..] Preserving target machine's hardware-configuration.nix from backup...${NC}"
        run_as_root cp -a "$BACKUP_ETC/hardware-configuration.nix" "$TARGET_ETC_DIR/hardware-configuration.nix"
        echo -e "${GREEN}[OK] Restored machine hardware-configuration.nix (mounts & UUIDs preserved).${NC}"
    elif [ ! -f "$TARGET_ETC_DIR/hardware-configuration.nix" ]; then
        if command -v nixos-generate-config &>/dev/null; then
            echo -e "${CYAN}[..] Generating fresh hardware-configuration.nix via nixos-generate-config...${NC}"
            run_as_root nixos-generate-config --dir "$TARGET_ETC_DIR"
            echo -e "${GREEN}[OK] Generated fresh hardware-configuration.nix.${NC}"
        elif [ -f "$NIXOS_SRC/hardware-configuration.nix" ]; then
            echo -e "${YELLOW}[..] Deploying repository default hardware-configuration.nix template...${NC}"
            run_as_root cp -a "$NIXOS_SRC/hardware-configuration.nix" "$TARGET_ETC_DIR/hardware-configuration.nix"
            echo -e "${YELLOW}[!] Note: Please edit ${TARGET_ETC_DIR}/hardware-configuration.nix with your root/boot UUIDs.${NC}"
        fi
    else
        echo -e "${GREEN}[OK] hardware-configuration.nix already present in ${TARGET_ETC_DIR}.${NC}"
    fi

    # 4. Stage deployed files in git if /etc/nixos is a git repository (required for Flake visibility)
    if [ -d "$TARGET_ETC_DIR/.git" ] || ( cd "$TARGET_ETC_DIR" 2>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null ); then
        echo -e "${CYAN}[..] Staging deployed NixOS configuration files in git for Flake visibility...${NC}"
        run_as_root git -C "$TARGET_ETC_DIR" add -N configuration.nix flake.nix hardware-configuration.nix Scripts .gitignore 2>/dev/null || true
    fi

    echo -e "${GREEN}[OK] NixOS flake and configuration deployment complete.${NC}"
    echo -e "${YELLOW}-> You can now rebuild your system with: sudo nixos-rebuild switch --flake /etc/nixos#cosmo-cli${NC}"

    # 5. Deploy Caelestia user-space dotfiles
    bash "$SCRIPT_DIR/setup-caelestia.sh"
fi
