#!/usr/bin/env bash
# ============================================================
#  ~/.config/hypr/wallpaper.sh
#  Usage:
#    wallpaper.sh ~/Pictures/Wallpapers/main.png
#    wallpaper.sh --pick    (rofi picker)
#    wallpaper.sh --random  (random from wallpaper dir)
# ============================================================

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
LAST_WALL="$HOME/.cache/current_wallpaper"

# ── Argument handling ─────────────────────────────────────────

case "$1" in
    --pick)
        cd "$WALLPAPER_DIR" || exit 1
        IFS=$'\n'
        WALLPAPER=$(for f in $(ls -t *.png *.jpg *.jpeg *.webp 2>/dev/null); do
            echo -en "$f\0icon\x1f$WALLPAPER_DIR/$f\n"
        done | rofi -dmenu -show-icons -p "Wallpaper" -i)
        unset IFS
        [[ -z "$WALLPAPER" ]] && exit 0
        WALLPAPER="$WALLPAPER_DIR/$WALLPAPER"
        ;;
    --random)
        WALLPAPER=$(find "$WALLPAPER_DIR" \
            -type f \( -iname "*.jpg" -o -iname "*.jpeg" \
                    -o -iname "*.png" -o -iname "*.webp" \) \
            | shuf -n 1)
        ;;
    "")
        [[ -f "$LAST_WALL" ]] && WALLPAPER=$(cat "$LAST_WALL") || {
            echo "No wallpaper specified."
            exit 1
        }
        ;;
    *)
        WALLPAPER="$1"
        ;;
esac

[[ ! -f "$WALLPAPER" ]] && echo "Error: $WALLPAPER not found" && exit 1

echo "Applying wallpaper: $WALLPAPER"
mkdir -p "$(dirname "$LAST_WALL")"
echo "$WALLPAPER" > "$LAST_WALL"

# ── Ensure swww daemon is running ─────────────────────────────

if ! pgrep -x swww-daemon > /dev/null 2>&1; then
    swww-daemon --no-cache &
    sleep 1
fi

# ── Set wallpaper via swww directly ──────────────────────────
swww img "$WALLPAPER"     --transition-type  grow     --transition-pos   center     --transition-duration 1.5     --transition-fps   60

# ── Run matugen for colour extraction only (no wallpaper) ────
matugen image "$WALLPAPER" --mode dark --source-color-index 0

# ── Patch dunst colours ───────────────────────────────────────

if [[ -f ~/.config/waybar/colors.css ]]; then
    PRIMARY=$(grep "@define-color primary " ~/.config/waybar/colors.css | grep -o '#[0-9a-fA-F]*' | head -1)
    BG=$(grep "@define-color background " ~/.config/waybar/colors.css | grep -o '#[0-9a-fA-F]*' | head -1)
    FG=$(grep "@define-color on_background " ~/.config/waybar/colors.css | grep -o '#[0-9a-fA-F]*' | head -1)
    ERR=$(grep "@define-color error " ~/.config/waybar/colors.css | grep -o '#[0-9a-fA-F]*' | head -1)

    if [[ -n "$PRIMARY" && -n "$BG" ]]; then
        sed -i "s/background *= *\"#[0-9a-fA-F]*\"/background = \"$BG\"/g"    ~/.config/dunst/dunstrc
        sed -i "s/foreground *= *\"#[0-9a-fA-F]*\"/foreground = \"$FG\"/g"    ~/.config/dunst/dunstrc
        sed -i "/urgency_normal/,/^\[/ s/frame_color *= *\"#[0-9a-fA-F]*\"/frame_color = \"$PRIMARY\"/" ~/.config/dunst/dunstrc
        sed -i "/urgency_critical/,/^\[/ s/background *= *\"#[0-9a-fA-F]*\"/background = \"${ERR:-#a82010}\"/" ~/.config/dunst/dunstrc
        pkill dunst || true
        dunst &
        disown
    fi
fi

# ── Reload GTK (Thunar picks this up) ────────────────────────

gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null
sleep 0.3
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'      2>/dev/null

# Kill Thunar so it reloads with new theme on next open
pkill thunar 2>/dev/null || true

# ── Sync wallpaper to SDDM ───────────────────────────────────
sudo /usr/local/bin/sddm-set-wallpaper "$WALLPAPER" 2>/dev/null || true

# ── Sync theme to Limine bootloader ──────────────────────────
if [[ -f ~/.config/waybar/colors.css ]]; then
    PRIMARY=$(grep "@define-color primary " ~/.config/waybar/colors.css | grep -o '#[0-9a-fA-F]*' | head -1 | sed 's/#//')
    SECONDARY=$(grep "@define-color outline " ~/.config/waybar/colors.css | grep -o '#[0-9a-fA-F]*' | head -1 | sed 's/#//')
    if [[ -n "$PRIMARY" ]]; then
        sudo /usr/local/bin/limine-set-theme "$WALLPAPER" "$PRIMARY" "$SECONDARY" 2>/dev/null || true
    fi
fi

echo "Done — theme applied from: $(basename "$WALLPAPER")"
