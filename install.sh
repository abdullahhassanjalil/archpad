#!/usr/bin/env bash
# ============================================================
#  Abdullah's Hyprland Desktop Installer
#  Tested on: Arch Linux (minimal TTY install)
#  Run as your normal user (not root) after base Arch install
#  Usage: bash install.sh
# ============================================================

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/hyprland-install.log"
DOTFILES="$INSTALLER_DIR/dotfiles"

# ── Logging ───────────────────────────────────────────────────
log()     { echo -e "${GREEN}[✓]${NC} $*" | tee -a "$LOG_FILE"; }
info()    { echo -e "${BLUE}[i]${NC} $*" | tee -a "$LOG_FILE"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*" | tee -a "$LOG_FILE"; }
error()   { echo -e "${RED}[✗]${NC} $*" | tee -a "$LOG_FILE"; }
header()  { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}\n" | tee -a "$LOG_FILE"; }
step()    { echo -e "${BOLD}  → $*${NC}" | tee -a "$LOG_FILE"; }

# ── Banner ────────────────────────────────────────────────────
print_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
  ╦ ╦╦ ╦╔═╗╦═╗╦  ╔═╗╔╗╔╔╦╗
  ╠═╣╚╦╝╠═╝╠╦╝║  ╠═╣║║║ ║║
  ╩ ╩ ╩ ╩  ╩╚═╩═╝╩ ╩╝╚╝═╩╝
  Desktop Installer — Arch Linux
EOF
    echo -e "${NC}"
    echo -e "  ${BOLD}A fully themed Hyprland setup with auto-theming${NC}"
    echo -e "  ${BOLD}Waybar · Kitty · Neovim · SDDM · wlogout · yazi${NC}"
    echo ""
}

# ── Pre-flight checks ─────────────────────────────────────────
preflight() {
    header "Pre-flight Checks"

    # Must not be root
    if [[ "$EUID" -eq 0 ]]; then
        error "Do not run as root. Run as your normal user."
        exit 1
    fi
    log "Running as user: $USER"

    # Check internet
    step "Checking internet connection..."
    if ! ping -c1 archlinux.org &>/dev/null; then
        error "No internet connection. Please connect and retry."
        exit 1
    fi
    log "Internet connected"

    # Check pacman
    if ! command -v pacman &>/dev/null; then
        error "pacman not found — are you on Arch Linux?"
        exit 1
    fi
    log "Arch Linux detected"

    # Check sudo
    if ! sudo -n true 2>/dev/null; then
        info "This installer needs sudo. You may be prompted for your password."
        sudo -v || { error "sudo failed"; exit 1; }
    fi
    log "sudo available"
}

# ── User configuration ────────────────────────────────────────
configure() {
    header "Configuration"

    echo -e "${BOLD}Let's set up your desktop.${NC}"
    echo ""

    # Keyboard layout
    read -rp "  Keyboard layout (e.g. gb, us, de) [us]: " KB_LAYOUT
    KB_LAYOUT="${KB_LAYOUT:-us}"

    # Monitor resolution
    echo ""
    echo -e "  ${BOLD}Monitor setup${NC}"
    echo -e "  Leave blank to use 'preferred' (auto-detect)"
    read -rp "  Primary monitor resolution (e.g. 1920x1080) [preferred]: " MONITOR_RES
    MONITOR_RES="${MONITOR_RES:-preferred}"

    read -rp "  Monitor scale (e.g. 1, 1.25, 1.5) [1]: " MONITOR_SCALE
    MONITOR_SCALE="${MONITOR_SCALE:-1}"

    # Timezone
    echo ""
    read -rp "  Timezone (e.g. Europe/London) [UTC]: " TIMEZONE
    TIMEZONE="${TIMEZONE:-UTC}"

    # Git config
    echo ""
    echo -e "  ${BOLD}Git configuration (optional)${NC}"
    read -rp "  Git name [skip]: " GIT_NAME
    read -rp "  Git email [skip]: " GIT_EMAIL

    # Wallpaper preference
    echo ""
    echo -e "  ${BOLD}Initial wallpaper${NC}"
    echo -e "  The installer includes a default wallpaper."
    echo -e "  You can change it anytime with SUPER+W."

    echo ""
    echo -e "${BOLD}Summary:${NC}"
    echo -e "  Keyboard:  $KB_LAYOUT"
    echo -e "  Monitor:   $MONITOR_RES @ scale $MONITOR_SCALE"
    echo -e "  Timezone:  $TIMEZONE"
    [[ -n "$GIT_NAME" ]]  && echo -e "  Git name:  $GIT_NAME"
    [[ -n "$GIT_EMAIL" ]] && echo -e "  Git email: $GIT_EMAIL"
    echo ""

    read -rp "  Proceed with installation? [Y/n]: " CONFIRM
    CONFIRM="${CONFIRM:-Y}"
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi

    # Export for use in other functions
    export KB_LAYOUT MONITOR_RES MONITOR_SCALE TIMEZONE GIT_NAME GIT_EMAIL
}

# ── Install yay (AUR helper) ──────────────────────────────────
install_yay() {
    header "AUR Helper (yay)"

    if command -v yay &>/dev/null; then
        log "yay already installed"
        return
    fi

    step "Installing base-devel..."
    sudo pacman -S --needed --noconfirm base-devel git >> "$LOG_FILE" 2>&1

    step "Cloning and building yay..."
    local tmp
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp/yay" >> "$LOG_FILE" 2>&1
    (cd "$tmp/yay" && makepkg -si --noconfirm) >> "$LOG_FILE" 2>&1
    rm -rf "$tmp"
    log "yay installed"
}

# ── Install all packages ──────────────────────────────────────
install_packages() {
    header "Installing Packages"

    # ── Pacman packages ───────────────────────────────────────
    local pacman_pkgs=(
        # Hyprland ecosystem
        hyprland hyprpaper hyprlock hypridle hyprshot
        xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        xdg-utils xdg-user-dirs

        # Display / Wayland
        wayland wayland-protocols wlroots
        qt5-wayland qt6-wayland
        qt5ct qt6ct

        # Status bar
        waybar

        # Terminal
        kitty

        # App launcher
        rofi-wayland

        # File manager
        yazi ffmpegthumbnailer poppler fd ripgrep fzf zoxide imagemagick

        # Notifications
        dunst libnotify

        # Session manager
        wlogout

        # Fonts
        ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols
        noto-fonts noto-fonts-emoji

        # Icons
        papirus-icon-theme

        # Audio
        pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
        pavucontrol

        # Bluetooth
        bluez bluez-utils blueman

        # Network
        networkmanager network-manager-applet

        # Brightness
        brightnessctl

        # Polkit
        polkit-gnome

        # SDDM
        sddm qt6-svg

        # Wallpaper / theming
        swww matugen

        # Boot / Plymouth
        plymouth

        # Tree-sitter (for Neovim)
        tree-sitter-cli

        # Neovim
        neovim nodejs npm

        # GTK theming
        nwg-look adwaita-icon-theme

        # Utils
        git curl wget unzip tar gzip jq
        btop fastfetch
        bash-language-server
    )

    step "Installing pacman packages (this may take a while)..."
    sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}" >> "$LOG_FILE" 2>&1
    log "Pacman packages installed"

    # ── AUR packages ─────────────────────────────────────────
    local aur_pkgs=(
        unar
        swww
        matugen-bin
        hyprland-qtutils
    )

    step "Installing AUR packages..."
    yay -S --needed --noconfirm "${aur_pkgs[@]}" >> "$LOG_FILE" 2>&1
    log "AUR packages installed"
}

# ── Enable services ───────────────────────────────────────────
enable_services() {
    header "Enabling Services"

    step "Enabling SDDM..."
    sudo systemctl enable sddm >> "$LOG_FILE" 2>&1

    step "Enabling NetworkManager..."
    sudo systemctl enable NetworkManager >> "$LOG_FILE" 2>&1

    step "Enabling Bluetooth..."
    sudo systemctl enable bluetooth >> "$LOG_FILE" 2>&1

    step "Enabling Pipewire..."
    systemctl --user enable pipewire pipewire-pulse wireplumber >> "$LOG_FILE" 2>&1 || true

    step "Adding user to input group (for keyboard-state in Waybar)..."
    sudo usermod -aG input "$USER" >> "$LOG_FILE" 2>&1

    log "Services enabled"
}

# ── Deploy dotfiles ───────────────────────────────────────────
deploy_dotfiles() {
    header "Deploying Dotfiles"

    # ── Hyprland ──────────────────────────────────────────────
    step "Configuring Hyprland..."
    mkdir -p ~/.config/hypr
    # Substitute keyboard layout and monitor settings
    sed \
        -e "s/kb_layout    = \"gb\"/kb_layout    = \"$KB_LAYOUT\"/" \
        -e "s/mode     = \"preferred\"/mode     = \"$MONITOR_RES\"/" \
        -e "s/scale    = 1/scale    = $MONITOR_SCALE/" \
        "$DOTFILES/hypr/hyprland.lua" > ~/.config/hypr/hyprland.lua

    cp "$DOTFILES/hypr/hyprlock.conf"      ~/.config/hypr/hyprlock.conf
    cp "$DOTFILES/hypr/colors.lua"         ~/.config/hypr/colors.lua
    cp "$DOTFILES/hypr/wallpaper.sh"       ~/.config/hypr/wallpaper.sh
    cp "$DOTFILES/hypr/keybinds-popup.sh"  ~/.config/hypr/keybinds-popup.sh
    chmod +x ~/.config/hypr/wallpaper.sh
    chmod +x ~/.config/hypr/keybinds-popup.sh
    log "Hyprland configured"

    # ── Waybar ────────────────────────────────────────────────
    step "Configuring Waybar..."
    mkdir -p ~/.config/waybar
    cp "$DOTFILES/waybar/config.jsonc" ~/.config/waybar/config.jsonc
    cp "$DOTFILES/waybar/style.css"    ~/.config/waybar/style.css
    log "Waybar configured"

    # ── Rofi ──────────────────────────────────────────────────
    step "Configuring Rofi..."
    mkdir -p ~/.config/rofi
    cp "$DOTFILES/rofi/config.rasi" ~/.config/rofi/config.rasi
    cp "$DOTFILES/rofi/theme.rasi"  ~/.config/rofi/theme.rasi
    log "Rofi configured"

    # ── Kitty ─────────────────────────────────────────────────
    step "Configuring Kitty..."
    mkdir -p ~/.config/kitty
    cp "$DOTFILES/kitty/kitty.conf"   ~/.config/kitty/kitty.conf
    cp "$DOTFILES/kitty/colors.conf"  ~/.config/kitty/colors.conf 2>/dev/null || \
        touch ~/.config/kitty/colors.conf
    log "Kitty configured"

    # ── Dunst ─────────────────────────────────────────────────
    step "Configuring Dunst..."
    mkdir -p ~/.config/dunst
    cp "$DOTFILES/dunst/dunstrc" ~/.config/dunst/dunstrc
    log "Dunst configured"

    # ── Wlogout ───────────────────────────────────────────────
    step "Configuring wlogout..."
    mkdir -p ~/.config/wlogout
    cp "$DOTFILES/wlogout/layout"    ~/.config/wlogout/layout
    cp "$DOTFILES/wlogout/style.css" ~/.config/wlogout/style.css
    log "wlogout configured"

    # ── Matugen ───────────────────────────────────────────────
    step "Configuring matugen..."
    mkdir -p ~/.config/matugen/templates
    cp "$DOTFILES/matugen/config.toml" ~/.config/matugen/config.toml
    cp "$DOTFILES/matugen/templates/"* ~/.config/matugen/templates/
    log "Matugen configured"

    # ── GTK ───────────────────────────────────────────────────
    step "Configuring GTK..."
    mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
    cp "$DOTFILES/gtk-3.0/gtk.css" ~/.config/gtk-3.0/gtk.css
    cp "$DOTFILES/gtk-4.0/gtk.css" ~/.config/gtk-4.0/gtk.css
    touch ~/.config/gtk-3.0/colors.css
    touch ~/.config/gtk-4.0/colors.css
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'       2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus'      2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 11' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    log "GTK configured"

    # ── Neovim ────────────────────────────────────────────────
    step "Configuring Neovim..."
    mkdir -p ~/.config/nvim/lua/{core,plugins,themes} ~/.config/nvim/colors
    cp "$DOTFILES/nvim/init.lua"                   ~/.config/nvim/init.lua
    cp "$DOTFILES/nvim/lua/core/options.lua"       ~/.config/nvim/lua/core/options.lua
    cp "$DOTFILES/nvim/lua/core/keymaps.lua"       ~/.config/nvim/lua/core/keymaps.lua
    cp "$DOTFILES/nvim/lua/core/autocmds.lua"      ~/.config/nvim/lua/core/autocmds.lua
    cp "$DOTFILES/nvim/lua/plugins/init.lua"       ~/.config/nvim/lua/plugins/init.lua
    cp "$DOTFILES/nvim/colors/matugen.lua"         ~/.config/nvim/colors/matugen.lua
    cp "$DOTFILES/nvim/lua/themes/matugen_colors.lua" ~/.config/nvim/lua/themes/matugen_colors.lua
    log "Neovim configured"

    # ── XDG user dirs ─────────────────────────────────────────
    step "Creating XDG directories..."
    xdg-user-dirs-update >> "$LOG_FILE" 2>&1 || true
    mkdir -p ~/Pictures/Wallpapers ~/Pictures/Screenshots
    log "XDG directories created"

    # ── Git config ────────────────────────────────────────────
    if [[ -n "${GIT_NAME:-}" ]]; then
        git config --global user.name "$GIT_NAME"
    fi
    if [[ -n "${GIT_EMAIL:-}" ]]; then
        git config --global user.email "$GIT_EMAIL"
    fi
}

# ── Install SDDM theme ────────────────────────────────────────
install_sddm() {
    header "SDDM Theme"

    step "Installing retro-warm SDDM theme..."
    sudo mkdir -p /usr/share/sddm/themes/retro-warm
    sudo cp "$DOTFILES/sddm-retro/Main.qml"          /usr/share/sddm/themes/retro-warm/
    sudo cp "$DOTFILES/sddm-retro/theme.conf"         /usr/share/sddm/themes/retro-warm/
    sudo cp "$DOTFILES/sddm-retro/metadata.desktop"   /usr/share/sddm/themes/retro-warm/

    step "Setting SDDM theme..."
    sudo mkdir -p /etc/sddm.conf.d
    echo -e "[Theme]\nCurrent=retro-warm" | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null

    step "Installing SDDM helper scripts..."
    sudo tee /usr/local/bin/sddm-set-wallpaper > /dev/null << 'SCRIPT'
#!/bin/bash
if [[ -n "$1" ]]; then
    cp "$1" /usr/share/sddm/themes/retro-warm/background.png
    chmod 644 /usr/share/sddm/themes/retro-warm/background.png
fi
if [[ -f "/home/$SUDO_USER/.config/matugen/sddm-theme-generated.conf" ]]; then
    cp "/home/$SUDO_USER/.config/matugen/sddm-theme-generated.conf" \
       /usr/share/sddm/themes/retro-warm/theme.conf
    chmod 644 /usr/share/sddm/themes/retro-warm/theme.conf
fi
SCRIPT
    sudo chmod 755 /usr/local/bin/sddm-set-wallpaper

    step "Installing Limine helper script..."
    sudo tee /usr/local/bin/limine-set-theme > /dev/null << 'SCRIPT'
#!/bin/bash
WALLPAPER="$1"
PRIMARY="$2"
SECONDARY="$3"
[[ -f "$WALLPAPER" ]] && cp "$WALLPAPER" /boot/limine/wallpaper.png
[[ -f /boot/limine/limine.conf ]] && {
    sed -i "s/interface_branding_color:.*/interface_branding_color: $PRIMARY/" /boot/limine/limine.conf
    sed -i "s/interface_help_color:.*/interface_help_color: $SECONDARY/"       /boot/limine/limine.conf
}
SCRIPT
    sudo chmod 755 /usr/local/bin/limine-set-theme

    step "Setting up sudoers rules..."
    echo "$USER ALL=(ALL) NOPASSWD: /usr/local/bin/sddm-set-wallpaper" \
        | sudo tee /etc/sudoers.d/sddm-wallpaper > /dev/null
    echo "$USER ALL=(ALL) NOPASSWD: /usr/local/bin/limine-set-theme" \
        | sudo tee /etc/sudoers.d/limine-theme > /dev/null
    sudo chmod 440 /etc/sudoers.d/sddm-wallpaper /etc/sudoers.d/limine-theme

    log "SDDM configured"
}

# ── Plymouth ──────────────────────────────────────────────────
install_plymouth() {
    header "Plymouth Boot Splash"

    step "Installing retro-warm Plymouth theme..."
    sudo mkdir -p /usr/share/plymouth/themes/retro-warm
    sudo cp "$DOTFILES/plymouth/retro-warm.plymouth" \
            /usr/share/plymouth/themes/retro-warm/
    sudo cp "$DOTFILES/plymouth/retro-warm.script"   \
            /usr/share/plymouth/themes/retro-warm/
    sudo cp "$DOTFILES/plymouth/logo.png"            \
            /usr/share/plymouth/themes/retro-warm/
    sudo cp "$DOTFILES/plymouth/progress_bar.png"    \
            /usr/share/plymouth/themes/retro-warm/
    sudo cp "$DOTFILES/plymouth/progress_box.png"    \
            /usr/share/plymouth/themes/retro-warm/

    step "Configuring mkinitcpio for Plymouth..."
    # Add i915 to MODULES if not present
    if ! grep -q "i915" /etc/mkinitcpio.conf; then
        sudo sed -i 's/^MODULES=(/MODULES=(i915 /' /etc/mkinitcpio.conf
    fi
    # Add plymouth hook after base if not present
    if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
        sudo sed -i 's/^HOOKS=(base/HOOKS=(base plymouth/' /etc/mkinitcpio.conf
    fi

    step "Setting Plymouth theme..."
    sudo plymouth-set-default-theme -R retro-warm >> "$LOG_FILE" 2>&1 || \
        warn "Plymouth theme set failed — run 'sudo plymouth-set-default-theme -R retro-warm' manually"

    step "Adding quiet splash to kernel cmdline..."
    if [[ -f /etc/kernel/cmdline ]]; then
        if ! grep -q "quiet splash" /etc/kernel/cmdline; then
            local current
            current=$(cat /etc/kernel/cmdline)
            echo -n "$current quiet splash" | sudo tee /etc/kernel/cmdline > /dev/null
        fi
    fi

    step "Rebuilding initramfs..."
    sudo mkinitcpio -P >> "$LOG_FILE" 2>&1

    log "Plymouth configured"
}

# ── Wallpaper ─────────────────────────────────────────────────
setup_wallpaper() {
    header "Initial Wallpaper & Theme"

    # Copy default wallpaper
    step "Installing default wallpaper..."
    cp "$DOTFILES/wallpaper/default.png" ~/Pictures/Wallpapers/default.png

    # Start swww daemon
    step "Starting swww daemon..."
    swww-daemon --no-cache &
    sleep 1

    # Apply initial theme
    step "Generating initial colour theme..."
    ~/.config/hypr/wallpaper.sh ~/Pictures/Wallpapers/default.png || \
        warn "Initial theme generation failed — run wallpaper.sh after first login"

    log "Wallpaper and theme applied"
}

# ── Neovim plugins ────────────────────────────────────────────
install_nvim_plugins() {
    header "Neovim Plugins"

    step "Installing Neovim plugins (headless)..."
    nvim --headless "+Lazy! sync" +qa >> "$LOG_FILE" 2>&1 || \
        warn "Neovim plugin install had issues — open nvim after login to complete"

    log "Neovim plugins installed"
}

# ── Final setup ───────────────────────────────────────────────
final_setup() {
    header "Final Setup"

    step "Setting timezone..."
    sudo timedatectl set-timezone "$TIMEZONE" >> "$LOG_FILE" 2>&1 || true

    step "Enabling NTP..."
    sudo timedatectl set-ntp true >> "$LOG_FILE" 2>&1 || true

    step "Setting up XDG portal config..."
    mkdir -p ~/.config/xdg-desktop-portal
    cat > ~/.config/xdg-desktop-portal/hyprland-portals.conf << 'EOF'
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Settings=gtk
EOF

    step "Installing Papirus folder colours..."
    papirus-folders -C orange --theme Papirus-Dark >> "$LOG_FILE" 2>&1 || true

    log "Final setup complete"
}

# ── Summary ───────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${BOLD}${GREEN}╔══════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║   Installation Complete! 🎉           ║${NC}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}What's installed:${NC}"
    echo -e "  • Hyprland 0.55 (Lua config)"
    echo -e "  • Waybar + auto-theming"
    echo -e "  • Kitty terminal"
    echo -e "  • Neovim with LSP + plugins"
    echo -e "  • Rofi app launcher"
    echo -e "  • yazi file manager"
    echo -e "  • SDDM retro-warm login screen"
    echo -e "  • Plymouth boot splash"
    echo -e "  • matugen auto-theming pipeline"
    echo -e "  • wlogout session manager"
    echo ""
    echo -e "  ${BOLD}Key bindings:${NC}"
    echo -e "  SUPER + Return    Terminal"
    echo -e "  SUPER + Space     App launcher"
    echo -e "  SUPER + E         File manager"
    echo -e "  SUPER + W         Change wallpaper"
    echo -e "  SUPER + /         Keybind cheatsheet"
    echo -e "  SUPER + SHIFT+Q   Session manager"
    echo ""
    echo -e "  ${BOLD}Log file:${NC} ~/hyprland-install.log"
    echo ""
    echo -e "  ${YELLOW}Note: Log out and back in for group changes"
    echo -e "  (input group) to take effect.${NC}"
    echo ""
    read -rp "  Reboot now? [Y/n]: " REBOOT
    REBOOT="${REBOOT:-Y}"
    if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
        sudo reboot
    fi
}

# ── Main ──────────────────────────────────────────────────────
main() {
    print_banner
    preflight
    configure

    # Start logging
    echo "Installation started: $(date)" > "$LOG_FILE"

    install_yay
    install_packages
    enable_services
    deploy_dotfiles
    install_sddm
    install_plymouth
    setup_wallpaper
    install_nvim_plugins
    final_setup
    print_summary
}

main "$@"
