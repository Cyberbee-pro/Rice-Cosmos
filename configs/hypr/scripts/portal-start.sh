#!/usr/bin/env bash

# Export Wayland session context to D-Bus and systemd
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE

# Clean up existing portal instances
pkill -f xdg-desktop-portal

# Resolve dynamic Nix store paths
HYPRLAND_PORTAL=""
for p in /nix/store/*-xdg-desktop-portal-hyprland-*/libexec/xdg-desktop-portal-hyprland; do
    [ -x "$p" ] && HYPRLAND_PORTAL="$p"
done

MAIN_PORTAL=""
for p in /nix/store/*-xdg-desktop-portal-*/libexec/xdg-desktop-portal; do
    case "$p" in
        *hyprland*) continue ;;
    esac
    [ -x "$p" ] && MAIN_PORTAL="$p"
done

# Launch detached background portal processes
if [ -n "$HYPRLAND_PORTAL" ] && [ -n "$MAIN_PORTAL" ]; then
    nohup "$HYPRLAND_PORTAL" >/dev/null 2>&1 & disown
    sleep 1
    nohup "$MAIN_PORTAL" >/dev/null 2>&1 & disown
fi
