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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    # -------------------------------------------------------------------------
    # NixOS Hardware Configuration & Declarative Module Generator
    # -------------------------------------------------------------------------
    TARGET_ETC_DIR="/etc/nixos"
    REPO_HW_CONFIG="${SCRIPT_DIR}/nixos/hardware-configuration.nix"
    TARGET_HW_CONFIG="${TARGET_ETC_DIR}/hardware-configuration.nix"

    run_as_root() {
        if [ "$EUID" -eq 0 ]; then
            "$@"
        elif [ "$1" != "nixos-generate-config" ] && [ -w "$TARGET_ETC_DIR" ]; then
            "$@"
        elif command -v sudo &>/dev/null; then
            sudo "$@"
        else
            "$@"
        fi
    }

    if [ ! -d "$TARGET_ETC_DIR" ]; then
        echo -e "${YELLOW}[..] Directory ${TARGET_ETC_DIR} not found. Creating with elevated permissions...${NC}"
        run_as_root mkdir -p "$TARGET_ETC_DIR"
    fi

    backup_hw_config() {
        if [ -e "$TARGET_HW_CONFIG" ] || [ -L "$TARGET_HW_CONFIG" ]; then
            local backup_path
            backup_path="${TARGET_HW_CONFIG}.backup_$(date +%Y%m%d_%H%M%S)"
            local count=1
            while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
                backup_path="${TARGET_HW_CONFIG}.backup_$(date +%Y%m%d_%H%M%S)_${count}"
                count=$((count + 1))
            done
            echo -e "${YELLOW}[..] Creating backup of existing hardware configuration: ${backup_path}${NC}"
            run_as_root cp -a "$TARGET_HW_CONFIG" "$backup_path"
        fi
    }

    echo -e "\n${CYAN}=== NixOS Hardware Configuration ===${NC}"
    echo -e "Do you want to use the repository's pre-configured hardware-configuration.nix (optimized for Lenovo LOQ), or auto-generate a fresh one for this machine?"
    echo -e "  ${CYAN}[1]${NC} Use repo default"
    echo -e "  ${CYAN}[2]${NC} Auto-generate fresh via nixos-generate-config"

    hw_choice=""
    if [ -t 0 ]; then
        read -rp "Select option [1-2, default: 1]: " hw_choice || hw_choice="1"
    elif read -r piped_input; then
        hw_choice="$piped_input"
    else
        echo -e "${YELLOW}[!] Non-interactive terminal detected. Defaulting to Option [1].${NC}"
        hw_choice="1"
    fi

    case "${hw_choice:-1}" in
        2)
            echo -e "${CYAN}[..] Auto-generating fresh hardware-configuration.nix via nixos-generate-config...${NC}"
            if ! command -v nixos-generate-config &>/dev/null; then
                echo -e "${RED}[ERR] nixos-generate-config not found in PATH. Falling back to repo default.${NC}"
                backup_hw_config
                if [ -f "$REPO_HW_CONFIG" ]; then
                    run_as_root cp "$REPO_HW_CONFIG" "$TARGET_HW_CONFIG"
                    echo -e "${GREEN}[OK] Repository hardware configuration deployed to ${TARGET_HW_CONFIG}.${NC}"
                else
                    echo -e "${RED}[ERR] Source configuration missing at ${REPO_HW_CONFIG}.${NC}"
                fi
            else
                backup_hw_config
                if run_as_root nixos-generate-config --dir "$TARGET_ETC_DIR"; then
                    echo -e "${GREEN}[OK] Fresh hardware-configuration.nix generated successfully in ${TARGET_ETC_DIR}.${NC}"
                else
                    echo -e "${RED}[ERR] nixos-generate-config failed. Falling back to repo default.${NC}"
                    if [ -f "$REPO_HW_CONFIG" ]; then
                        run_as_root cp "$REPO_HW_CONFIG" "$TARGET_HW_CONFIG"
                        echo -e "${GREEN}[OK] Repository hardware configuration deployed to ${TARGET_HW_CONFIG}.${NC}"
                    fi
                fi
            fi
            ;;
        1|*)
            if [ -n "$hw_choice" ] && [ "$hw_choice" != "1" ]; then
                echo -e "${YELLOW}[!] Invalid input '${hw_choice}'. Defaulting to Option [1] (Use repo default).${NC}"
            fi
            echo -e "${CYAN}[..] Deploying repository pre-configured hardware-configuration.nix...${NC}"
            if [ -f "$REPO_HW_CONFIG" ]; then
                backup_hw_config
                run_as_root cp "$REPO_HW_CONFIG" "$TARGET_HW_CONFIG"
                echo -e "${GREEN}[OK] Repository hardware configuration deployed to ${TARGET_HW_CONFIG}.${NC}"
            else
                echo -e "${RED}[ERR] Source configuration missing at ${REPO_HW_CONFIG}.${NC}"
            fi
            ;;
    esac

    # Declarative NixOS Generator
    echo -e "\n${CYAN}[..] Generating Declarative NixOS Module for Themes . . . .${NC}"
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