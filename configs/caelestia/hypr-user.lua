-- =============================================================================
--  CAELESTIA HYPRLAND USER CONFIGURATION
-- =============================================================================
-- User tweaks, autostart, environment variables, window rules, and keybindings
-- using Caelestia's hl.* Lua API. Supports Arch Linux and NixOS.

-- 1. Input Configuration (NumLock enabled by default)
hl.config({
    input = {
        numlock_by_default = true,
    },
})

-- 2. Autostart Authentication Agent (Cross-Distro: Arch Linux & NixOS)
local function get_polkit_agent()
    local candidates = {
        "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
        "/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1",
        "/usr/libexec/polkit-gnome-authentication-agent-1",
    }
    for _, path in ipairs(candidates) do
        local f = io.open(path, "r")
        if f then
            f:close()
            return path
        end
    end
    -- Fallback command that tests at runtime in shell
    return "if [ -x /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]; then /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1; elif [ -x /run/current-system/sw/libexec/polkit-gnome-authentication-agent-1 ]; then /run/current-system/sw/libexec/polkit-gnome-authentication-agent-1; fi"
end

hl.on("hyprland.start", function ()
    hl.exec_cmd(get_polkit_agent() .. " &")
end)

-- 3. NVIDIA & Wayland Environment Variables
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "0")
hl.env("QT_SCALE_FACTOR", "1")

-- 4. Window Rules
-- Floating centered solid-opacity window rule for Satty screenshot editor
hl.window_rule({
    name    = "satty-floating-center",
    match   = { class = ".*[Ss]atty.*" },
    float   = true,
    center  = true,
    opacity = "1.0 override 1.0 override",
})

-- 5. Helper Script Paths
local home_dir      = os.getenv("HOME") or ""
local toggle_hz_cmd = home_dir .. "/.local/bin/toggle-hz.sh"
local gamemode_cmd  = home_dir .. "/.local/bin/gamemode.sh"
local opacity_cmd   = home_dir .. "/.local/bin/toggle-opacity.sh"

-- 6. Screenshot Bindings
local satty_cmd = "mkdir -p ~/Pictures/Screenshots && GEOM=$(slurp) && grim -g \"$GEOM\" - | satty --filename - --output-filename ~/Pictures/Screenshots/satty-%Y-%m-%d_%H-%M-%S.png --copy-command wl-copy --early-exit"

hl.bind("Print",                       hl.dsp.exec_cmd(satty_cmd))
hl.bind("SUPER + SHIFT + S",           hl.dsp.exec_cmd(satty_cmd))
hl.bind("SUPER + CTRL + SHIFT + S",   hl.dsp.exec_cmd("caelestia screenshot"))
hl.bind("SUPER + Print",               hl.dsp.exec_cmd("caelestia screenshot"))

-- 7. Lenovo LOQ 15ARP9 Copilot Key Hardware Keybinds -> toggle-hz.sh
hl.bind("SUPER + SHIFT + code:201",         hl.dsp.exec_cmd(toggle_hz_cmd))
hl.bind("SUPER + XF86Assistant",            hl.dsp.exec_cmd(toggle_hz_cmd))
hl.bind("SUPER + SHIFT + XF86TouchpadOff",  hl.dsp.exec_cmd(toggle_hz_cmd))
-- Note: SUPER + ALT + R is intentionally left untouched for Caelestia's screen recorder

-- 8. Performance & Desktop Helper Bindings
hl.bind("SUPER + ALT + G", hl.dsp.exec_cmd(gamemode_cmd))
hl.bind("SUPER + ALT + O", hl.dsp.exec_cmd(opacity_cmd))
hl.bind("Home",            hl.dsp.exec_cmd(opacity_cmd))
