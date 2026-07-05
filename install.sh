#!/usr/bin/env bash
# ============================================================
#  ARCHPAD — Hyprland Desktop Installer
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
LOG_FILE="$HOME/archpad-install.log"
DOTFILES="$INSTALLER_DIR/dotfiles"

# ── Logging ───────────────────────────────────────────────────
log()    { echo -e "${GREEN}[✓]${NC} $*" | tee -a "$LOG_FILE"; }
info()   { echo -e "${BLUE}[i]${NC} $*" | tee -a "$LOG_FILE"; }
warn()   { echo -e "${YELLOW}[!]${NC} $*" | tee -a "$LOG_FILE"; }
error()  { echo -e "${RED}[✗]${NC} $*" | tee -a "$LOG_FILE"; }
header() { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}\n" | tee -a "$LOG_FILE"; }
step()   { echo -e "${BOLD}  → $*${NC}" | tee -a "$LOG_FILE"; }

# ── Banner ────────────────────────────────────────────────────
print_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
    _    ____   ____ _   _ ____   _    ____
   / \  |  _ \ / ___| | | |  _ \ / \  |  _ \
  / _ \ | |_) | |   | |_| | |_) / _ \ | | | |
 / ___ \|  _ <| |___|  _  |  __/ ___ \| |_| |
/_/   \_\_| \_\\____|_| |_|_| /_/   \_\____/

  Hyprland Desktop Installer — Arch Linux
EOF
    echo -e "${NC}"
    echo -e "  ${BOLD}Fully themed Hyprland setup with auto-theming${NC}"
    echo -e "  ${BOLD}Waybar · Kitty · Neovim · SDDM · wlogout · yazi${NC}"
    echo ""
}

# ── Pre-flight checks ─────────────────────────────────────────
preflight() {
    header "Pre-flight Checks"

    [[ "$EUID" -eq 0 ]] && { error "Do not run as root."; exit 1; }
    log "Running as user: $USER"

    step "Checking internet..."
    ping -c1 archlinux.org &>/dev/null || { error "No internet connection."; exit 1; }
    log "Internet connected"

    command -v pacman &>/dev/null || { error "Not Arch Linux."; exit 1; }
    log "Arch Linux detected"

    sudo -v || { error "sudo failed"; exit 1; }
    log "sudo available"

    # Check dotfiles exist
    [[ -f "$DOTFILES/hypr/hyprland.lua" ]] || {
        error "Dotfiles not found at $DOTFILES"
        error "Run setup-dotfiles.sh first on your configured system"
        exit 1
    }
    log "Dotfiles found"
}

# ── User configuration ────────────────────────────────────────
configure() {
    header "Configuration"
    echo -e "${BOLD}Let's set up your desktop.${NC}\n"

    read -rp "  Keyboard layout (e.g. gb, us, de) [us]: " KB_LAYOUT
    KB_LAYOUT="${KB_LAYOUT:-us}"

    echo -e "\n  ${BOLD}Monitor setup${NC}"
    read -rp "  Resolution (e.g. 1920x1080) [preferred]: " MONITOR_RES
    MONITOR_RES="${MONITOR_RES:-preferred}"
    read -rp "  Scale (e.g. 1, 1.25, 1.5) [1]: " MONITOR_SCALE
    MONITOR_SCALE="${MONITOR_SCALE:-1}"

    echo ""
    read -rp "  Timezone (e.g. Europe/London) [UTC]: " TIMEZONE
    TIMEZONE="${TIMEZONE:-UTC}"

    echo -e "\n  ${BOLD}Git (optional)${NC}"
    read -rp "  Name [skip]: " GIT_NAME
    read -rp "  Email [skip]: " GIT_EMAIL

    echo -e "\n${BOLD}Summary:${NC}"
    echo -e "  Keyboard : $KB_LAYOUT"
    echo -e "  Monitor  : $MONITOR_RES @ scale $MONITOR_SCALE"
    echo -e "  Timezone : $TIMEZONE"
    [[ -n "${GIT_NAME:-}"  ]] && echo -e "  Git name : $GIT_NAME"
    [[ -n "${GIT_EMAIL:-}" ]] && echo -e "  Git email: $GIT_EMAIL"
    echo ""

    read -rp "  Proceed? [Y/n]: " CONFIRM
    [[ "${CONFIRM:-Y}" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

    export KB_LAYOUT MONITOR_RES MONITOR_SCALE TIMEZONE GIT_NAME GIT_EMAIL
}

# ── Install yay ───────────────────────────────────────────────
install_yay() {
    header "AUR Helper (yay)"

    if command -v yay &>/dev/null; then
        log "yay already installed"
        return
    fi

    step "Installing base-devel..."
    sudo pacman -S --needed --noconfirm base-devel git >> "$LOG_FILE" 2>&1

    step "Building yay..."
    local tmp
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp/yay" >> "$LOG_FILE" 2>&1
    (cd "$tmp/yay" && makepkg -si --noconfirm) >> "$LOG_FILE" 2>&1
    rm -rf "$tmp"
    log "yay installed"
}

# ── Install packages ──────────────────────────────────────────
install_packages() {
    header "Installing Packages"

    local pacman_pkgs=(
        # Hyprland
        hyprland hyprlock hypridle hyprshot
        xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        xdg-utils xdg-user-dirs

        # Wayland
        wayland wayland-protocols
        qt5-wayland qt6-wayland qt5ct qt6ct

        # Waybar
        waybar

        # Terminal
        kitty

        # Launcher
        rofi-wayland

        # File manager
        yazi ffmpegthumbnailer poppler fd ripgrep fzf zoxide imagemagick

        # Notifications + session
        dunst libnotify

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

        # Brightness / polkit
        brightnessctl polkit-gnome

        # SDDM
        sddm qt6-svg

        # Plymouth
        plymouth

        # Neovim
        tree-sitter-cli neovim nodejs npm

        # GTK
        nwg-look adwaita-icon-theme

        # Shell
        zsh

        # Utils
        git curl wget unzip tar gzip jq btop fastfetch
    )

    local aur_pkgs=(
        unar
        swww
        matugen-bin
        wlogout
        hyprpaper
        papirus-folders-git
        oh-my-zsh-git
        wlogout
    )

    step "Installing pacman packages..."
    local failed=()
    for pkg in "${pacman_pkgs[@]}"; do
        echo -ne "    ${CYAN}Installing${NC} $pkg...\r"
        if ! sudo pacman -S --needed --noconfirm "$pkg" >> "$LOG_FILE" 2>&1; then
            warn "Failed: $pkg"
            failed+=("$pkg")
        fi
    done
    [[ ${#failed[@]} -gt 0 ]] && warn "Failed packages: ${failed[*]}"
    log "Pacman packages done"

    step "Installing bash-language-server via npm..."
    sudo npm install -g bash-language-server >> "$LOG_FILE" 2>&1 || warn "bash-language-server failed"

    step "Installing AUR packages..."
    for pkg in "${aur_pkgs[@]}"; do
        echo -ne "    ${CYAN}Installing${NC} $pkg...\r"
        yay -S --needed --noconfirm "$pkg" >> "$LOG_FILE" 2>&1 || warn "AUR failed: $pkg"
    done
    log "AUR packages done"
}

# ── Enable services ───────────────────────────────────────────
enable_services() {
    header "Enabling Services"

    step "SDDM..."
    sudo systemctl enable sddm >> "$LOG_FILE" 2>&1

    step "NetworkManager..."
    sudo systemctl enable NetworkManager >> "$LOG_FILE" 2>&1

    step "Bluetooth..."
    sudo systemctl enable bluetooth >> "$LOG_FILE" 2>&1

    step "Pipewire..."
    systemctl --user enable pipewire pipewire-pulse wireplumber >> "$LOG_FILE" 2>&1 || true

    step "Adding user to groups..."
    sudo usermod -aG input,video,audio,wheel "$USER" >> "$LOG_FILE" 2>&1

    # Fix SDDM PAM config — prevents login issues
    step "Fixing SDDM PAM..."
    sudo tee /etc/pam.d/sddm > /dev/null << 'EOF'
#%PAM-1.0
auth        include     system-login
account     include     system-login
password    include     system-login
session     include     system-login
EOF

    log "Services enabled"
}

# ── Deploy dotfiles ───────────────────────────────────────────
deploy_dotfiles() {
    header "Deploying Dotfiles"

    # ── Hyprland ─────────────────────────────────────────────
    step "Hyprland..."
    mkdir -p ~/.config/hypr
    sed \
        -e "s/kb_layout    = \"gb\"/kb_layout    = \"$KB_LAYOUT\"/" \
        -e "s/mode     = \"preferred\"/mode     = \"$MONITOR_RES\"/" \
        -e "s/scale    = 1/scale    = $MONITOR_SCALE/" \
        "$DOTFILES/hypr/hyprland.lua" > ~/.config/hypr/hyprland.lua
    cp "$DOTFILES/hypr/hyprlock.conf"     ~/.config/hypr/hyprlock.conf
    cp "$DOTFILES/hypr/colors.lua"        ~/.config/hypr/colors.lua
    cp "$DOTFILES/hypr/wallpaper.sh"      ~/.config/hypr/wallpaper.sh
    cp "$DOTFILES/hypr/keybinds-popup.sh" ~/.config/hypr/keybinds-popup.sh
    chmod +x ~/.config/hypr/wallpaper.sh ~/.config/hypr/keybinds-popup.sh
    log "Hyprland"

    # ── Waybar ───────────────────────────────────────────────
    step "Waybar..."
    mkdir -p ~/.config/waybar
    cp "$DOTFILES/waybar/config.jsonc" ~/.config/waybar/config.jsonc
    cp "$DOTFILES/waybar/style.css"    ~/.config/waybar/style.css
    log "Waybar"

    # ── Rofi ─────────────────────────────────────────────────
    step "Rofi..."
    mkdir -p ~/.config/rofi
    cp "$DOTFILES/rofi/config.rasi" ~/.config/rofi/config.rasi
    cp "$DOTFILES/rofi/theme.rasi"  ~/.config/rofi/theme.rasi
    log "Rofi"

    # ── Kitty ────────────────────────────────────────────────
    step "Kitty..."
    mkdir -p ~/.config/kitty
    cp "$DOTFILES/kitty/kitty.conf" ~/.config/kitty/kitty.conf
    touch ~/.config/kitty/colors.conf
    log "Kitty"

    # ── Dunst ────────────────────────────────────────────────
    step "Dunst..."
    mkdir -p ~/.config/dunst
    cp "$DOTFILES/dunst/dunstrc" ~/.config/dunst/dunstrc
    log "Dunst"

    # ── Wlogout ──────────────────────────────────────────────
    step "Wlogout..."
    mkdir -p ~/.config/wlogout
    cp "$DOTFILES/wlogout/layout"    ~/.config/wlogout/layout
    cp "$DOTFILES/wlogout/style.css" ~/.config/wlogout/style.css
    log "Wlogout"

    # ── Matugen ──────────────────────────────────────────────
    step "Matugen..."
    mkdir -p ~/.config/matugen/templates
    cp "$DOTFILES/matugen/config.toml"    ~/.config/matugen/config.toml
    cp "$DOTFILES/matugen/templates/"*    ~/.config/matugen/templates/
    log "Matugen"

    # ── GTK ──────────────────────────────────────────────────
    step "GTK..."
    mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
    cp "$DOTFILES/gtk-3.0/gtk.css" ~/.config/gtk-3.0/gtk.css
    cp "$DOTFILES/gtk-4.0/gtk.css" ~/.config/gtk-4.0/gtk.css
    touch ~/.config/gtk-3.0/colors.css ~/.config/gtk-4.0/colors.css
    gsettings set org.gnome.desktop.interface gtk-theme    'Adwaita'                   2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme   'Papirus'                   2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name    'JetBrainsMono Nerd Font 11' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'               2>/dev/null || true
    log "GTK"

    # ── Neovim ───────────────────────────────────────────────
    step "Neovim..."
    mkdir -p ~/.config/nvim/lua/{core,plugins,themes} ~/.config/nvim/colors
    cp "$DOTFILES/nvim/init.lua"                      ~/.config/nvim/init.lua
    cp "$DOTFILES/nvim/lua/core/options.lua"          ~/.config/nvim/lua/core/options.lua
    cp "$DOTFILES/nvim/lua/core/keymaps.lua"          ~/.config/nvim/lua/core/keymaps.lua
    cp "$DOTFILES/nvim/lua/core/autocmds.lua"         ~/.config/nvim/lua/core/autocmds.lua
    cp "$DOTFILES/nvim/lua/plugins/init.lua"          ~/.config/nvim/lua/plugins/init.lua
    cp "$DOTFILES/nvim/colors/matugen.lua"            ~/.config/nvim/colors/matugen.lua
    cp "$DOTFILES/nvim/lua/themes/matugen_colors.lua" ~/.config/nvim/lua/themes/matugen_colors.lua
    log "Neovim"

    # ── Fastfetch ─────────────────────────────────────────────
    step "Fastfetch..."
    mkdir -p ~/.config/fastfetch
    cp "$DOTFILES/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
    cp "$DOTFILES/fastfetch/archpad.txt"  ~/.config/fastfetch/archpad.txt
    log "Fastfetch"

    # ── XDG dirs ─────────────────────────────────────────────
    step "XDG directories..."
    xdg-user-dirs-update >> "$LOG_FILE" 2>&1 || true
    mkdir -p ~/Pictures/Wallpapers ~/Pictures/Screenshots
    log "XDG directories"

    # ── Git ──────────────────────────────────────────────────
    [[ -n "${GIT_NAME:-}"  ]] && git config --global user.name  "$GIT_NAME"
    [[ -n "${GIT_EMAIL:-}" ]] && git config --global user.email "$GIT_EMAIL"
}

# ── SDDM ──────────────────────────────────────────────────────
install_sddm() {
    header "SDDM Theme"

    step "Installing retro-warm theme..."
    sudo mkdir -p /usr/share/sddm/themes/retro-warm
    sudo cp "$DOTFILES/sddm-retro/Main.qml"        /usr/share/sddm/themes/retro-warm/
    sudo cp "$DOTFILES/sddm-retro/theme.conf"       /usr/share/sddm/themes/retro-warm/
    sudo cp "$DOTFILES/sddm-retro/metadata.desktop" /usr/share/sddm/themes/retro-warm/

    # Copy default wallpaper to SDDM
    [[ -f "$DOTFILES/wallpaper/default.png" ]] && \
        sudo cp "$DOTFILES/wallpaper/default.png" \
                /usr/share/sddm/themes/retro-warm/background.png

    step "Setting theme..."
    sudo mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=retro-warm\n' | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null

    step "Installing helper scripts..."
    sudo tee /usr/local/bin/sddm-set-wallpaper > /dev/null << 'SCRIPT'
#!/bin/bash
[[ -n "$1" ]] && cp "$1" /usr/share/sddm/themes/retro-warm/background.png && \
    chmod 644 /usr/share/sddm/themes/retro-warm/background.png
CONF="/home/${SUDO_USER}/.config/matugen/sddm-theme-generated.conf"
[[ -f "$CONF" ]] && cp "$CONF" /usr/share/sddm/themes/retro-warm/theme.conf && \
    chmod 644 /usr/share/sddm/themes/retro-warm/theme.conf
SCRIPT
    sudo chmod 755 /usr/local/bin/sddm-set-wallpaper

    sudo tee /usr/local/bin/limine-set-theme > /dev/null << 'SCRIPT'
#!/bin/bash
[[ -f "$1" ]] && cp "$1" /boot/limine/wallpaper.png
[[ -f /boot/limine/limine.conf ]] && {
    sed -i "s/interface_branding_color:.*/interface_branding_color: $2/" /boot/limine/limine.conf
    sed -i "s/interface_help_color:.*/interface_help_color: $3/"         /boot/limine/limine.conf
}
SCRIPT
    sudo chmod 755 /usr/local/bin/limine-set-theme

    step "Sudoers rules..."
    printf '%s ALL=(ALL) NOPASSWD: /usr/local/bin/sddm-set-wallpaper\n' "$USER" \
        | sudo tee /etc/sudoers.d/sddm-wallpaper > /dev/null
    printf '%s ALL=(ALL) NOPASSWD: /usr/local/bin/limine-set-theme\n' "$USER" \
        | sudo tee /etc/sudoers.d/limine-theme > /dev/null
    sudo chmod 440 /etc/sudoers.d/sddm-wallpaper /etc/sudoers.d/limine-theme

    log "SDDM configured"
}

# ── Plymouth ──────────────────────────────────────────────────
install_plymouth() {
    header "Plymouth Boot Splash"

    if [[ ! -d "$DOTFILES/plymouth" ]]; then
        warn "Plymouth dotfiles not found — skipping"
        return
    fi

    step "Installing theme..."
    sudo mkdir -p /usr/share/plymouth/themes/retro-warm
    sudo cp "$DOTFILES/plymouth/"* /usr/share/plymouth/themes/retro-warm/

    step "Configuring mkinitcpio..."
    grep -q "i915" /etc/mkinitcpio.conf || \
        sudo sed -i 's/^MODULES=(/MODULES=(i915 /' /etc/mkinitcpio.conf
    grep -q "plymouth" /etc/mkinitcpio.conf || \
        sudo sed -i 's/^HOOKS=(base/HOOKS=(base plymouth/' /etc/mkinitcpio.conf

    step "Setting theme and rebuilding initramfs..."
    sudo plymouth-set-default-theme -R retro-warm >> "$LOG_FILE" 2>&1 || \
        warn "Plymouth theme failed — set manually after reboot"

    step "Kernel cmdline..."
    if [[ -f /etc/kernel/cmdline ]]; then
        grep -q "quiet splash" /etc/kernel/cmdline || \
            printf '%s quiet splash' "$(cat /etc/kernel/cmdline)" \
            | sudo tee /etc/kernel/cmdline > /dev/null
        sudo mkinitcpio -P >> "$LOG_FILE" 2>&1
    fi

    log "Plymouth configured"
}

# ── Wallpaper & theme ─────────────────────────────────────────
setup_wallpaper() {
    header "Initial Wallpaper & Theme"

    step "Copying default wallpaper..."
    cp "$DOTFILES/wallpaper/default.png" ~/Pictures/Wallpapers/default.png

    step "Starting swww..."
    swww-daemon --no-cache &
    sleep 1

    step "Applying initial theme..."
    ~/.config/hypr/wallpaper.sh ~/Pictures/Wallpapers/default.png \
        >> "$LOG_FILE" 2>&1 || warn "Theme generation failed — run wallpaper.sh after login"

    log "Wallpaper and theme applied"
}

# ── Shell setup ───────────────────────────────────────────────
setup_shell() {
    header "Shell Setup"

    step "Setting zsh as default shell..."
    if command -v zsh &>/dev/null; then
        sudo chsh -s "$(command -v zsh)" "$USER" >> "$LOG_FILE" 2>&1 || \
            warn "Could not set zsh as default — run: chsh -s \$(which zsh)"
    fi

    step "Setting up zshrc..."
    if [[ ! -f ~/.zshrc ]]; then
        cat > ~/.zshrc << 'ZSHRC'
# Basic zshrc — customise as needed
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
[[ -f $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# System info
fastfetch
ZSHRC
    else
        # Add fastfetch to existing zshrc if not present
        grep -q "fastfetch" ~/.zshrc || echo -e '\n# System info\nfastfetch' >> ~/.zshrc
    fi

    log "Shell configured"
}

# ── Neovim plugins ────────────────────────────────────────────
install_nvim_plugins() {
    header "Neovim Plugins"

    step "Installing plugins (headless)..."
    nvim --headless "+Lazy! sync" +qa >> "$LOG_FILE" 2>&1 || \
        warn "Neovim plugins — open nvim after login to complete"

    log "Neovim plugins done"
}

# ── Final setup ───────────────────────────────────────────────
final_setup() {
    header "Final Setup"

    step "Timezone..."
    sudo timedatectl set-timezone "$TIMEZONE" >> "$LOG_FILE" 2>&1 || true
    sudo timedatectl set-ntp true >> "$LOG_FILE" 2>&1 || true

    step "XDG portal config..."
    mkdir -p ~/.config/xdg-desktop-portal
    cat > ~/.config/xdg-desktop-portal/hyprland-portals.conf << 'EOF'
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Settings=gtk
EOF

    step "Papirus folder colours..."
    papirus-folders -C orange --theme Papirus-Dark >> "$LOG_FILE" 2>&1 || true

    step "Enabling user services..."
    systemctl --user enable pipewire pipewire-pulse wireplumber >> "$LOG_FILE" 2>&1 || true

    log "Final setup done"
}

# ── Summary ───────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${BOLD}${GREEN}╔══════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║   ARCHPAD Installation Complete!  ║${NC}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Installed:${NC}"
    echo -e "  • Hyprland 0.55    • Waybar         • Kitty"
    echo -e "  • Neovim + LSP     • Rofi           • yazi"
    echo -e "  • SDDM theme       • Plymouth       • matugen"
    echo -e "  • wlogout          • Dunst          • fastfetch"
    echo ""
    echo -e "  ${BOLD}Key bindings:${NC}"
    echo -e "  SUPER + Return     Terminal"
    echo -e "  SUPER + Space      App launcher"
    echo -e "  SUPER + E          File manager (yazi)"
    echo -e "  SUPER + W          Change wallpaper + theme"
    echo -e "  SUPER + /          Keybind cheatsheet"
    echo -e "  SUPER + SHIFT+Q    Session manager"
    echo -e "  SUPER + Escape     Lock screen"
    echo ""
    echo -e "  ${YELLOW}Log out and back in for group changes to take effect${NC}"
    echo -e "  ${BOLD}Log:${NC} ~/archpad-install.log"
    echo ""
    read -rp "  Reboot now? [Y/n]: " REBOOT
    [[ "${REBOOT:-Y}" =~ ^[Yy]$ ]] && sudo reboot
}

# ── Main ──────────────────────────────────────────────────────
main() {
    print_banner
    preflight
    configure

    echo "ARCHPAD install started: $(date)" > "$LOG_FILE"

    install_yay
    install_packages
    enable_services
    deploy_dotfiles
    install_sddm
    install_plymouth
    setup_wallpaper
    setup_shell
    install_nvim_plugins
    final_setup
    print_summary
}

main "$@"
