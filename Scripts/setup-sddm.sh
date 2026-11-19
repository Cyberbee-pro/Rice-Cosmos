#!/usr/bin/env bash

# ==============================================================================
#  COSMOS RICE : Standalone SDDM & QYLock Theme Setup
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

echo -e "${CYAN}[..] Configuring SDDM Display Manager & QYLock Theme (${DISTRO^^}) . . . .${NC}"

if [ "$DISTRO" = "nixos" ]; then
    echo -e "${YELLOW}[i] NixOS manages SDDM and display themes declaratively via configuration.nix. Skipping mutable setup & systemctl.${NC}"
    exit 0
fi

# 1. Resolve root privileges
RUN_AS_ROOT="sudo"
if [ "$EUID" -eq 0 ]; then
    RUN_AS_ROOT=""
elif ! command -v sudo &>/dev/null; then
    echo -e "${RED}[ERR] sudo command not found. Root privileges required.${NC}"
    exit 1
fi

# 2. Install SDDM and Qt6 dependencies via pacman
SDDM_PKGS=(
    sddm
    qt6-svg
    qt6-declarative
    qt5-graphicaleffects
    qt5-quickcontrols2
    qt5-svg
)

missing_pkgs=()
for pkg in "${SDDM_PKGS[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        missing_pkgs+=("$pkg")
    fi
done

if [ ${#missing_pkgs[@]} -gt 0 ]; then
    echo -e "${YELLOW}[..] Installing SDDM packages via pacman: ${missing_pkgs[*]}...${NC}"
    # shellcheck disable=SC2086
    $RUN_AS_ROOT pacman -S --needed --noconfirm "${missing_pkgs[@]}"
fi

# 3. Download & Install Darkkal44/qylock theme
DOWNLOAD_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/cosmos/downloads"
mkdir -p "$DOWNLOAD_CACHE"

QYLOCK_DIR="$DOWNLOAD_CACHE/qylock"
if [ ! -d "$QYLOCK_DIR/.git" ]; then
    echo -e "${CYAN}[..] Cloning Darkkal44/qylock SDDM theme...${NC}"
    rm -rf "$QYLOCK_DIR"
    git clone https://github.com/Darkkal44/qylock "$QYLOCK_DIR"
else
    echo -e "${CYAN}[..] Updating Darkkal44/qylock SDDM theme...${NC}"
    git -C "$QYLOCK_DIR" pull --ff-only 2>/dev/null || true
fi

if [ -f "$QYLOCK_DIR/sddm.sh" ]; then
    echo -e "${CYAN}[..] Running QYLock installer script...${NC}"
    (
        cd "$QYLOCK_DIR"
        chmod +x sddm.sh 2>/dev/null || true
        # shellcheck disable=SC2086
        $RUN_AS_ROOT bash ./sddm.sh
    )
    echo -e "${GREEN}[OK] QYLock SDDM theme installed.${NC}"
elif [ -d "$QYLOCK_DIR/nier-automata" ]; then
    # Direct fallback copy if sddm.sh is not present
    # shellcheck disable=SC2086
    $RUN_AS_ROOT mkdir -p /usr/share/sddm/themes/
    # shellcheck disable=SC2086
    $RUN_AS_ROOT cp -rf "$QYLOCK_DIR/nier-automata" /usr/share/sddm/themes/
    echo -e "${GREEN}[OK] QYLock theme copied to /usr/share/sddm/themes/.${NC}"
fi

# 4. Set Current=nier-automata in /etc/sddm.conf.d/theme.conf for Qt6
echo -e "${CYAN}[..] Setting Current=nier-automata in /etc/sddm.conf.d/theme.conf...${NC}"
# shellcheck disable=SC2086
$RUN_AS_ROOT mkdir -p /etc/sddm.conf.d

cat << 'EOF' | if [ -n "$RUN_AS_ROOT" ]; then sudo tee /etc/sddm.conf.d/theme.conf >/dev/null; else tee /etc/sddm.conf.d/theme.conf >/dev/null; fi
[Theme]
Current=nier-automata
EOF

echo -e "${GREEN}[OK] Configured /etc/sddm.conf.d/theme.conf.${NC}"

# 5. Enable sddm.service on boot
echo -e "${CYAN}[..] Enabling sddm.service on boot...${NC}"
# shellcheck disable=SC2086
$RUN_AS_ROOT systemctl enable sddm.service
echo -e "${GREEN}[OK] sddm.service enabled on boot.${NC}"
