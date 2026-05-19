# Hyprland Desktop Installer

A fully themed Hyprland desktop setup for Arch Linux — inspired by Omarchy.
One script installs and configures everything from a minimal TTY Arch install.

## What's included

| Component        | App                          |
|-----------------|------------------------------|
| Compositor      | Hyprland 0.55 (Lua config)   |
| Status bar      | Waybar                       |
| Terminal        | Kitty                        |
| Editor          | Neovim + LSP + plugins       |
| App launcher    | Rofi                         |
| File manager    | yazi                         |
| Notifications   | Dunst                        |
| Session manager | wlogout                      |
| Login screen    | SDDM (retro-warm theme)      |
| Boot splash     | Plymouth (retro-warm theme)  |
| Auto-theming    | matugen + swww               |
| Lock screen     | hyprlock                     |

## Prerequisites

A minimal Arch Linux install with:
- A user account with sudo
- Internet connection
- `git` installed (`sudo pacman -S git`)

## Installation

```bash
git clone https://github.com/yourusername/hyprland-dotfiles
cd hyprland-dotfiles
bash install.sh
```

The installer will ask you:
- Keyboard layout (e.g. `gb`, `us`, `de`)
- Monitor resolution (leave blank for auto-detect)
- Monitor scale (e.g. `1`, `1.25` for HiDPI)
- Timezone
- Git name/email (optional)

## Auto-theming

Change your wallpaper and everything updates automatically:

```bash
# Pick a wallpaper (SUPER+W in the desktop)
~/.config/hypr/wallpaper.sh --pick

# Apply a specific wallpaper
~/.config/hypr/wallpaper.sh ~/Pictures/Wallpapers/photo.png

# Random wallpaper
~/.config/hypr/wallpaper.sh --random
```

When you change wallpaper:
- Waybar colours update
- Kitty terminal colours update
- Neovim colourscheme updates
- Hyprland window borders update
- SDDM login screen updates
- Limine bootloader updates
- Dunst notification colours update
- Rofi launcher colours update
- GTK app colours update

## Key bindings

| Keys                | Action                    |
|--------------------|---------------------------|
| SUPER + Return      | Open terminal (Kitty)     |
| SUPER + Space       | App launcher (Rofi)       |
| SUPER + E           | File manager (yazi)       |
| SUPER + W           | Change wallpaper          |
| SUPER + Q           | Close window              |
| SUPER + F           | Fullscreen                |
| SUPER + V           | Toggle floating           |
| SUPER + /           | Keybind cheatsheet        |
| SUPER + SHIFT+Q     | Session manager (wlogout) |
| SUPER + SHIFT+R     | Reload Hyprland config    |
| SUPER + Escape      | Lock screen               |
| SUPER + H/J/K/L     | Focus window              |
| SUPER + 1-9         | Switch workspace          |
| SUPER + SHIFT+1-9   | Move window to workspace  |
| Print               | Screenshot (full screen)  |
| SUPER + Print       | Screenshot (select area)  |

## Structure

```
dotfiles/
├── hypr/           Hyprland, hyprlock, wallpaper script
├── waybar/         Waybar config and style
├── rofi/           Rofi config and theme
├── kitty/          Kitty terminal config
├── nvim/           Neovim config with plugins
├── dunst/          Dunst notifications
├── wlogout/        Session manager
├── matugen/        Auto-theming templates
├── gtk-3.0/        GTK3 theme
├── gtk-4.0/        GTK4 theme
├── sddm-retro/     SDDM login theme
├── plymouth/       Plymouth boot splash
└── wallpaper/      Default wallpaper
```

## Post-install notes

- Log out and back in after install for group changes to take effect
- Add your wallpapers to `~/Pictures/Wallpapers/`
- For multi-monitor setups, edit `~/.config/hypr/hyprland.lua`
- Full install log at `~/hyprland-install.log`
