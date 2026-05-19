-- ============================================================
--  Hyprland Config — ThinkPad T480 · Arch Linux
--  Format : Lua (Hyprland ≥ 0.55)
--  Place at : ~/.config/hypr/hyprland.lua
--  Updated  : May 2026
--
--  Key dispatcher reference (from official example):
--    Focus direction  : hl.dsp.focus({ direction = "left" })
--    Focus workspace  : hl.dsp.focus({ workspace = 1 })
--    Move win to ws   : hl.dsp.window.move({ workspace = 1 })
--    Move win dir     : hyprctl dispatch movewindow <l/r/u/d>
--    Float toggle     : hl.dsp.window.float({ action = "toggle" })
--    Close window     : hl.dsp.window.close()
--    Fullscreen       : hl.dsp.window.fullscreen()
--    Pseudotile       : hl.dsp.window.pseudo()
--    Exec             : hl.dsp.exec_cmd("cmd")
-- ============================================================


-- ============================================================
--  PROGRAMS
-- ============================================================

local terminal    = "kitty"
local fileManager = "kitty --class yazi -e yazi"
local launcher    = "rofi -show drun"
local mainMod     = "SUPER"


-- ============================================================
--  MONITOR
-- ============================================================

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1.60,
})


-- ============================================================
--  ENVIRONMENT VARIABLES
-- ============================================================

hl.env("QT_QPA_PLATFORM",      "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GDK_BACKEND",          "wayland,x11,*")
hl.env("SDL_VIDEODRIVER",      "wayland")
hl.env("MOZ_ENABLE_WAYLAND",   "1")
hl.env("XDG_CURRENT_DESKTOP",  "Hyprland")
hl.env("XDG_SESSION_TYPE",     "wayland")
hl.env("XDG_SESSION_DESKTOP",  "Hyprland")
hl.env("XCURSOR_SIZE",         "24")
hl.env("XCURSOR_THEME",        "Adwaita")
hl.env("HYPRCURSOR_SIZE",      "24")


-- ============================================================
--  AUTOSTART
-- ============================================================

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("swww-daemon")
    hl.exec_cmd("sleep 1 && ~/.config/hypr/wallpaper.sh")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("dunst")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
end)


-- ============================================================
--  INPUT
-- ============================================================

hl.config({
    input = {
        kb_layout    = "gb",          -- change to "us" if needed
        kb_options   = "caps:escape", -- CapsLock → Escape; remove if unwanted
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll       = true,
            tap_to_click         = true,
            disable_while_typing = true,
            scroll_factor        = 0.8,
        },
    },
})


-- ============================================================
--  GENERAL
--  Border color: single solid hex color only — gradients
--  are broken in 0.55 Lua. Use a solid color for now.
-- ============================================================

-- ── Dynamic border colours from matugen ──────────────────────
-- Read matugen-generated colours, fall back to defaults
local ok, theme_colors = pcall(require, "colors")
local active_border   = ok and theme_colors.active_border   or { colors = { "rgba(89b4faff)", "rgba(cba6f7ff)" }, angle = 45 }
local inactive_border = ok and theme_colors.inactive_border or "rgba(313244ff)"

hl.config({
    general = {
        gaps_in          = 5,
        gaps_out         = 10,
        border_size      = 2,
        col = {
            active_border   = active_border,
            inactive_border = inactive_border,
        },
        layout           = "dwindle",
        resize_on_border = true,
    },
})


-- ============================================================
--  DECORATION
-- ============================================================

hl.config({
    decoration = {
        rounding         = 10,
        active_opacity   = 1.0,
        inactive_opacity = 0.92,
        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = "0xee1a1a2e",
        },
        blur = {
            enabled           = true,
            size              = 6,
            passes            = 2,
            new_optimizations = true,
            vibrancy          = 0.1696,
        },
    },
})


-- ============================================================
--  ANIMATIONS
--  speed is in deciseconds (speed = 3 → 300ms)
-- ============================================================

hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "windows",      enabled = true, speed = 3,    bezier = "easeOutQuint",   style = "slide" })
hl.animation({ leaf = "windowsOut",   enabled = true, speed = 2,    bezier = "quick",          style = "slide" })
hl.animation({ leaf = "border",       enabled = true, speed = 3,    bezier = "easeOutQuint"                    })
hl.animation({ leaf = "fade",         enabled = true, speed = 2,    bezier = "easeInOutCubic"                  })
hl.animation({ leaf = "workspaces",   enabled = true, speed = 3,    bezier = "easeOutQuint",   style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.94, bezier = "almostLinear",   style = "fade"  })
hl.animation({ leaf = "workspacesOut",enabled = true, speed = 1.94, bezier = "almostLinear",   style = "fade"  })


-- ============================================================
--  DWINDLE LAYOUT
-- ============================================================

hl.config({
    dwindle = {
        preserve_split               = true,
        smart_split                  = false,
        smart_resizing               = true,
        permanent_direction_override = false,
        use_active_for_splits        = true,
        default_split_ratio          = 1.0,
    },
})


-- ============================================================
--  MISC
-- ============================================================

hl.config({
    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },
})


-- ============================================================
--  GESTURES — verified 0.55 API
-- ============================================================

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace"  })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })


-- ============================================================
--  WINDOW RULES — verified 0.55 hl.window_rule() API
-- ============================================================

hl.window_rule({ match = { class = "pavucontrol"            }, float = true })
hl.window_rule({ match = { class = "nm-connection-editor"   }, float = true })
hl.window_rule({ match = { class = "blueman-manager"        }, float = true })
hl.window_rule({ match = { class = "org.gnome.Calculator"   }, float = true })
hl.window_rule({ match = { class = "nautilus"                   }, float = true, size = {800, 600}, center = true })
hl.window_rule({ match = { title = "Picture-in-Picture"     }, float = true, pin = true })
hl.window_rule({ match = { class = "xdg-desktop-portal-gtk" }, float = true, center = true, size = {600, 400} })
hl.window_rule({ match = { class = "keybind-popup"          }, float = true, center = true, size = {700, 520}, pin = true })
hl.window_rule({ match = { class = "org.gnome.Nautilus" }, float = true, size = {1000, 650}, center = true })
hl.window_rule({ match = { class = "yazi" }, float = true, size = {1000, 650}, center = true })

-- ── Wlogout ───────────────────────────────────────────────────

hl.window_rule({ match = { class = "wlogout" }, fullscreen = true })
-- Blur for wlogout
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true, ignore_alpha = 0.5 })

-- ============================================================
--  KEYBINDINGS
--  All dispatchers verified against official example config.
-- ============================================================

-- ── Core ───────────────────────────────────────────────────

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal),                      { description = "Open terminal" })
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager),                   { description = "Open file manager" })
hl.bind(mainMod .. " + Space",  hl.dsp.exec_cmd(launcher),                      { description = "App launcher" })
hl.bind(mainMod .. " + Q",      hl.dsp.window.close(),                          { description = "Close window" })
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen(),                     { description = "Toggle fullscreen" })
hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }),     { description = "Toggle floating" })
hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo(),                         { description = "Toggle pseudotile" })

-- ── Session ────────────────────────────────────────────────

hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"), { description = "Reload config" })
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit(),                     { description = "Exit Hyprland" })
hl.bind(mainMod .. " + Escape",    hl.dsp.exec_cmd("hyprlock"),       { description = "Lock screen" })
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/.config/hypr/wallpaper.sh --pick"), { description = "Pick wallpaper + apply theme" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("wlogout -b 2 -c 0 -r 0 -m 0 --layout ~/.config/wlogout/layout --css ~/.config/wlogout/style.css"), { description = "Session manager" })

-- ── Focus (verified: hl.dsp.focus is top-level, not hl.dsp.window.focus) ──

hl.bind(mainMod .. " + H",     hl.dsp.focus({ direction = "left"  }), { description = "Focus left" })
hl.bind(mainMod .. " + J",     hl.dsp.focus({ direction = "down"  }), { description = "Focus down" })
hl.bind(mainMod .. " + K",     hl.dsp.focus({ direction = "up"    }), { description = "Focus up" })
hl.bind(mainMod .. " + L",     hl.dsp.focus({ direction = "right" }), { description = "Focus right" })

hl.bind(mainMod .. " + Left",  hl.dsp.focus({ direction = "left"  }), { description = "Focus left" })
hl.bind(mainMod .. " + Down",  hl.dsp.focus({ direction = "down"  }), { description = "Focus down" })
hl.bind(mainMod .. " + Up",    hl.dsp.focus({ direction = "up"    }), { description = "Focus up" })
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }), { description = "Focus right" })

-- ── Move windows (direction-based via hyprctl — no Lua dispatcher exists) ──

hl.bind(mainMod .. " + SHIFT + H",     hl.dsp.exec_cmd("hyprctl dispatch movewindow l"), { description = "Move window left" })
hl.bind(mainMod .. " + SHIFT + J",     hl.dsp.exec_cmd("hyprctl dispatch movewindow d"), { description = "Move window down" })
hl.bind(mainMod .. " + SHIFT + K",     hl.dsp.exec_cmd("hyprctl dispatch movewindow u"), { description = "Move window up" })
hl.bind(mainMod .. " + SHIFT + L",     hl.dsp.exec_cmd("hyprctl dispatch movewindow r"), { description = "Move window right" })

hl.bind(mainMod .. " + SHIFT + Left",  hl.dsp.exec_cmd("hyprctl dispatch movewindow l"), { description = "Move window left" })
hl.bind(mainMod .. " + SHIFT + Down",  hl.dsp.exec_cmd("hyprctl dispatch movewindow d"), { description = "Move window down" })
hl.bind(mainMod .. " + SHIFT + Up",    hl.dsp.exec_cmd("hyprctl dispatch movewindow u"), { description = "Move window up" })
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.exec_cmd("hyprctl dispatch movewindow r"), { description = "Move window right" })

-- ── Resize windows ─────────────────────────────────────────

hl.bind(mainMod .. " + CTRL + H",     hl.dsp.exec_cmd("hyprctl dispatch resizeactive -50 0"), { description = "Resize left",  repeating = true })
hl.bind(mainMod .. " + CTRL + J",     hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 50"), { description = "Resize down",  repeating = true })
hl.bind(mainMod .. " + CTRL + K",     hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -50"), { description = "Resize up",    repeating = true })
hl.bind(mainMod .. " + CTRL + L",     hl.dsp.exec_cmd("hyprctl dispatch resizeactive 50 0"), { description = "Resize right", repeating = true })

-- ── Workspaces (verified from official example) ────────────

for i = 1, 9 do
    local key = i
    hl.bind(mainMod .. " + " .. key,
        hl.dsp.focus({ workspace = i }),
        { description = "Go to workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key,
        hl.dsp.window.move({ workspace = i }),
        { description = "Move window to workspace " .. i })
end

-- Scratchpad (special workspace)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("scratch"),          { description = "Toggle scratchpad" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratch" }), { description = "Move to scratchpad" })

-- Scroll through workspaces with mouse wheel (verified from official example)
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "Prev workspace" })

-- ── Window cycling ─────────────────────────────────────────

hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("hyprctl dispatch cyclenext"), { description = "Cycle windows" })

-- ── Screenshots (hyprshot) ─────────────────────────────────

hl.bind("Print",                       hl.dsp.exec_cmd("hyprshot -m output"), { description = "Screenshot: full screen" })
hl.bind(mainMod .. " + Print",         hl.dsp.exec_cmd("hyprshot -m region"), { description = "Screenshot: select area" })
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("hyprshot -m window"), { description = "Screenshot: active window" })

-- ── Audio (ThinkPad Fn keys, verified from official example) ─

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),     { locked = true })

-- ── Brightness (verified from official example) ────────────

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- ── Display / Misc ─────────────────────────────────────────

hl.bind("XF86Display",         hl.dsp.exec_cmd("wdisplays"),                         { description = "Display settings" })
hl.bind(mainMod .. " + SLASH", hl.dsp.exec_cmd("~/.config/hypr/keybinds-popup.sh"), { description = "Keybind cheatsheet" })

-- ── Mouse window management (verified from official example) ─

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })


-- ============================================================
--  END OF CONFIG
-- ============================================================
