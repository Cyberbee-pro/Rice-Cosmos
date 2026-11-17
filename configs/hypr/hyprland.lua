-- =============================================================================
--  CYBERBEE'S HYPRLAND LUA CONFIGURATION (UNIFIED)
-- =============================================================================

--------------------------------------------------------------------------------
-- 1. MONITORS
--------------------------------------------------------------------------------
-- Native 1080p @ 144Hz with 1:1 pixel scaling
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@144.002",
    position = "0x0",
    scale    = "1",
})

--------------------------------------------------------------------------------
-- 2. DEFAULT PROGRAMS & VARIABLES
--------------------------------------------------------------------------------
local terminal    = "kitty"
local fileManager = "dolphin"
local browser     = "firefox"
local editor      = "code"
local menu        = "hyprlauncher"
local clipboard   = "copyq toggle"
local mainMod     = "SUPER"

--------------------------------------------------------------------------------
-- 3. AUTOSTART
--------------------------------------------------------------------------------
hl.on("hyprland.start", function ()
    -- 1. DBus & Systemd Wayland environment synchronization
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE XDG_SESSION_TYPE &")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE XDG_SESSION_TYPE &")
    hl.exec_cmd("systemctl --user reset-failed &")
    hl.exec_cmd("systemctl --user start xdg-desktop-portal.service &")

    -- 2. Hyprland Plugins
    hl.exec_cmd("hyprpm reload -n &")

    -- 3. Authentication Agent
    hl.exec_cmd("/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1 &")

    -- 4. Caelestia Desktop Shell
    hl.exec_cmd("caelestia-shell -d &")

    -- 5. Cursor Theme (Synced with phinger-cursors-dark)
    hl.exec_cmd("hyprctl setcursor phinger-cursors-dark 37")

    -- 6. Daemons & Background Tools
    hl.exec_cmd("copyq --start-server &")

    -- 7. Screen sharing script (if active)
    -- hl.exec_cmd("~/.config/hypr/scripts/portal-start.sh &")
end)

--------------------------------------------------------------------------------
-- 4. ENVIRONMENT VARIABLES
--------------------------------------------------------------------------------
hl.env("XCURSOR_THEME", "phinger-cursors-dark")
hl.env("XCURSOR_SIZE", "37")
hl.env("HYPRCURSOR_THEME", "phinger-cursors-dark")
hl.env("HYPRCURSOR_SIZE", "37")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "0")
hl.env("QT_SCALE_FACTOR", "1")

--------------------------------------------------------------------------------
-- 5. INPUT, CURSOR & GESTURES
--------------------------------------------------------------------------------
hl.config({
    input = {
        kb_layout          = "us",
        follow_mouse       = 1,
        numlock_by_default = true,
        sensitivity        = 0.5,

        touchpad = {
            natural_scroll       = true,
            scroll_factor        = 1.0,
            tap_to_click         = true,
            drag_lock            = true,
            disable_while_typing = true,
        },
    },

    cursor = {
        no_warps                 = false,
        warp_on_change_workspace = true,
        hide_on_key_press        = true,
        no_hardware_cursors      = 1,
    },

    gestures = {
        workspace_swipe_direction_lock = true,
        workspace_swipe_distance       = 200,
        workspace_swipe_forever        = true,
    },
})

-- Explicit override for Elan Touchpad
hl.device({
    name           = "elan06fa:00-04f3:327e-touchpad",
    sensitivity    = 0.0,
    natural_scroll = true,
    tap_to_click   = true,
    drag_lock      = true,
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

--------------------------------------------------------------------------------
-- 6. LOOK AND FEEL
--------------------------------------------------------------------------------
hl.config({
    general = {
        gaps_in          = 5,
        gaps_out         = 20,
        border_size      = 2,
        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
        snap = {
            enabled = true,
        },
    },

    decoration = {
        rounding         = 10,
        rounding_power   = 2,
        active_opacity   = 0.9,
        inactive_opacity = 0.65,
        dim_around       = 0.7,
        dim_inactive     = true,
        dim_strength     = 0.1,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled    = true,
            size       = 4,
            passes     = 2,
            brightness = 1.06,
            contrast   = 1.3,
            noise      = 0.0,
            vibrancy   = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        vrr                      = 1,
    },
})

--------------------------------------------------------------------------------
-- 7. ANIMATIONS & CURVES
--------------------------------------------------------------------------------
-- Curves & Springs
hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 }    } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0.0 },  { 0.1, 1.0 } } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

-- Window & Layer Animations
hl.animation({ leaf = "global",        enabled = true,  speed = 3.0,  bezier = "quick" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "borderangle",   enabled = true,  speed = 1.0,  bezier = "default" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })

-- Workspace Animations
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 5,    bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 5,    bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 5,    bezier = "easeOutQuint", style = "slide" })

hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

--------------------------------------------------------------------------------
-- 8. LAYOUTS
--------------------------------------------------------------------------------
hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

--------------------------------------------------------------------------------
-- 9. KEYBINDINGS
--------------------------------------------------------------------------------

-- --- Applications & Gaming ---
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(editor))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(clipboard))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("steam"))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("steam"))

-- --- Window Management ---
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT + Return",    hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"))

-- --- Opacity Toggle (Translucent 0.70 <-> Solid 1.0) ---
local is_solid = false
hl.bind("Home", function ()
    if is_solid then
        hl.config({
            decoration = {
                active_opacity   = 0.7,
                inactive_opacity = 0.65,
            },
        })
        is_solid = false
    else
        hl.config({
            decoration = {
                active_opacity   = 1.0,
                inactive_opacity = 1.0,
            },
        })
        is_solid = true
    end
end)

-- --- System & Performance Scripts ---
hl.bind(mainMod .. " + ALT + G", hl.dsp.exec_cmd("~/.local/bin/gamemode.sh"))
hl.bind(mainMod .. " + M",       hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- --- Refresh Rate 60Hz <-> 144Hz Toggle ---
hl.bind("F23",                       hl.dsp.exec_cmd("~/.local/bin/toggle-hz.sh"))
hl.bind("ALT + F23",                 hl.dsp.exec_cmd("~/.local/bin/toggle-hz.sh"))
hl.bind("SUPER + SHIFT + F23",       hl.dsp.exec_cmd("~/.local/bin/toggle-hz.sh"))
hl.bind("SUPER + SHIFT + ALT + F23", hl.dsp.exec_cmd("~/.local/bin/toggle-hz.sh"))
hl.bind(mainMod .. " + ALT + R",     hl.dsp.exec_cmd("~/.local/bin/toggle-hz.sh"))

-- --- Focus Navigation ---
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- --- Move Window in Layout ---
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.swap({ direction = "down" }))

-- --- Workspaces Navigation & Window Movement (1 - 10) ---
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- --- Scratchpad Workspace (Super + U) ---
hl.bind(mainMod .. " + U",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special:magic" }))

-- --- Mouse Drag / Resize ---
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })

-- --- Screenshots (Grim + Slurp + wl-clipboard) ---
-- hl.bind("Print",                   hl.dsp.exec_cmd("GEOM=$(slurp) && grim -g \"$GEOM\" - | wl-copy --type image/png && notify-send -a 'Screenshot' 'Snippet Copied' 'Image copied to clipboard'"))
-- hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("GEOM=$(slurp) && grim -g \"$GEOM\" - | wl-copy --type image/png && notify-send -a 'Screenshot' 'Snippet Copied' 'Image copied to clipboard'"))
-- hl.bind("SHIFT + Print",           hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && FILE=~/Pictures/Screenshots/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png && grim \"$FILE\" && wl-copy --type image/png < \"$FILE\" && notify-send -a 'Screenshot' 'Fullscreen Captured' 'Saved to ~/Pictures/Screenshots and copied to clipboard'"))
-- hl.bind(mainMod .. " + Print",     hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && FILE=~/Pictures/Screenshots/snip_$(date +%Y-%m-%d_%H-%M-%S).png && GEOM=$(slurp) && grim -g \"$GEOM\" \"$FILE\" && wl-copy --type image/png < \"$FILE\" && notify-send -a 'Screenshot' 'Snip Saved' 'Saved to ~/Pictures/Screenshots and copied to clipboard'"))

-- --- Screenshots (Satty Interactive HUD + Caelestia) ---
hl.bind("Print",                   hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && GEOM=$(slurp) && grim -g \"$GEOM\" - | satty --filename - --output-filename ~/Pictures/Screenshots/satty-%Y-%m-%d_%H-%M-%S.png --copy-command wl-copy --early-exit"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && GEOM=$(slurp) && grim -g \"$GEOM\" - | satty --filename - --output-filename ~/Pictures/Screenshots/satty-%Y-%m-%d_%H-%M-%S.png --copy-command wl-copy --early-exit"))
hl.bind(mainMod .. " + CTRL + SHIFT + S",  hl.dsp.exec_cmd("caelestia screenshot"))


-- --- Hardware Controls (Audio, Brightness, Media) ---
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, ["repeat"] = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, ["repeat"] = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, ["repeat"] = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, ["repeat"] = true })

-- Brightness Controls (Triggers Caelestia OSD Slider Toast with repeat support)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("caelestia shell brightness set '+1%'"), { locked = true, ["repeat"] = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("caelestia shell brightness set '1%-'"), { locked = true, ["repeat"] = true })

-- Media Playback Controls (Directly routed through Caelestia MPRIS target)
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("caelestia shell mpris next"),      { locked = true })
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("caelestia shell mpris playPause"), { locked = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("caelestia shell mpris playPause"), { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("caelestia shell mpris previous"),  { locked = true })

--------------------------------------------------------------------------------
-- 10. WINDOW & LAYER RULES
--------------------------------------------------------------------------------
-- Suppress standard maximize events across all windows
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix XWayland drag artifacts
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Hyprland Run Menu Placement
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- Force solid opacity for media/video players & Picture-in-Picture
hl.window_rule({
    name    = "solid-pip",
    match   = { title = ".*Picture[- ]in[- ][Pp]icture.*" },
    opacity = "1.0 override 1.0 override",
})

hl.window_rule({
    name    = "solid-media-players",
    match   = { class = "^(mpv|vlc|celluloid|io\\.github\\.celluloid_player\\.Celluloid)$" },
    opacity = "1.0 override 1.0 override",
})

-- CopyQ Floating Center Window
hl.window_rule({
    name   = "copyq-floating-center",
    match  = { class = "^(com\\.github\\.hluk\\.copyq|copyq)$" },
    float  = true,
    center = true,
    size   = "680 520",
})

-- Satty Screenshot Editor Floating Center Window
hl.window_rule({
    name    = "satty-floating-center",
    match   = { class = "^(com\\.gabm\\.satty|satty)$" },
    float   = true,
    center  = true,
    opacity = "1.0 override 1.0 override",
})