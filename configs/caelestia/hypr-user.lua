-- =============================================================================
--  CAELESTIA HYPRLAND USER CONFIGURATION
-- =============================================================================
-- User tweaks, autostart, environment variables, window rules, and keybindings
-- using Caelestia's hl.* Lua API.

-- 1. Input Configuration (NumLock enabled by default)
hl.config({
    input = {
        numlock_by_default = true,
    },
})

-- 2. Autostart Authentication Agent
hl.on("hyprland.start", function ()
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &")
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
