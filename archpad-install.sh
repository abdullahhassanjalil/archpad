#!/usr/bin/env bash
# ============================================================
#  ARCHPAD — Full Arch Linux Installer
#  Run from Arch Linux live ISO:
#    curl -sL https://raw.githubusercontent.com/abdullahhassanjalil/archpad/master/archpad-install.sh | bash
#  Or from USB:
#    bash archpad-install.sh
# ============================================================

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────
RED='\033[0;31m';  GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m';  BOLD='\033[1m'; NC='\033[0m'

log()    { echo -e "${GREEN}[✓]${NC} $*"; }
info()   { echo -e "${BLUE}[i]${NC} $*"; }
warn()   { echo -e "${YELLOW}[!]${NC} $*"; }
error()  { echo -e "${RED}[✗]${NC} $*"; exit 1; }
header() { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}\n"; }
ask()    { echo -e "${BOLD}  → $*${NC}"; }

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

  Full Arch Linux Installer
  Hyprland · Waybar · Neovim · SDDM · Auto-theming
EOF
    echo -e "${NC}"
    echo -e "  ${YELLOW}WARNING: This will format your selected drive!${NC}"
    echo ""
}

# ── Pre-flight ────────────────────────────────────────────────
preflight() {
    header "Pre-flight Checks"

    # Must be root (running from ISO)
    [[ "$EUID" -ne 0 ]] && error "Run as root from Arch ISO"
    log "Running as root"

    # Check internet
    ping -c1 archlinux.org &>/dev/null || error "No internet connection"
    log "Internet connected"

    # Check we're in UEFI mode
    [[ -d /sys/firmware/efi ]] || error "Not booted in UEFI mode. Enable UEFI in BIOS."
    log "UEFI mode confirmed"

    # Update system clock
    timedatectl set-ntp true
    log "System clock synced"
}

# ── User configuration ────────────────────────────────────────
configure() {
    header "System Configuration"

    # ── Disk selection ────────────────────────────────────────
    echo -e "${BOLD}Available disks:${NC}"
    lsblk -d -o NAME,SIZE,MODEL | grep -v "loop\|sr"
    echo ""
    ask "Install disk (e.g. sda, nvme0n1, sdb):"
    read -r DISK_NAME
    DISK="/dev/$DISK_NAME"
    [[ -b "$DISK" ]] || error "Disk $DISK not found"

    echo ""
    echo -e "${RED}${BOLD}WARNING: All data on $DISK will be erased!${NC}"
    ask "Type 'yes' to confirm:"
    read -r CONFIRM_DISK
    [[ "$CONFIRM_DISK" == "yes" ]] || { echo "Aborted."; exit 0; }

    # ── Partition scheme ──────────────────────────────────────
    echo ""
    echo -e "${BOLD}Partition scheme:${NC}"
    echo "  1) Single root partition (recommended)"
    echo "  2) Root + separate home"
    ask "Choice [1]:"
    read -r PART_SCHEME
    PART_SCHEME="${PART_SCHEME:-1}"

    # ── Filesystem ────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}Filesystem:${NC}"
    echo "  1) btrfs (recommended — supports snapshots)"
    echo "  2) ext4"
    ask "Choice [1]:"
    read -r FS_CHOICE
    FS_CHOICE="${FS_CHOICE:-1}"
    [[ "$FS_CHOICE" == "2" ]] && FILESYSTEM="ext4" || FILESYSTEM="btrfs"

    # ── Swap ─────────────────────────────────────────────────
    echo ""
    ask "Swap size in GB (0 to skip) [8]:"
    read -r SWAP_SIZE
    SWAP_SIZE="${SWAP_SIZE:-8}"

    # ── System ───────────────────────────────────────────────
    echo ""
    header "System Settings"

    ask "Hostname [archpad]:"
    read -r HOSTNAME
    HOSTNAME="${HOSTNAME:-archpad}"

    ask "Username:"
    read -r USERNAME
    [[ -n "$USERNAME" ]] || error "Username cannot be empty"

    ask "Password:"
    read -rs PASSWORD
    echo ""
    ask "Confirm password:"
    read -rs PASSWORD2
    echo ""
    [[ "$PASSWORD" == "$PASSWORD2" ]] || error "Passwords don't match"

    ask "Root password (leave blank to use same as user):"
    read -rs ROOT_PASSWORD
    echo ""
    [[ -z "$ROOT_PASSWORD" ]] && ROOT_PASSWORD="$PASSWORD"

    ask "Timezone (e.g. Europe/London) [UTC]:"
    read -r TIMEZONE
    TIMEZONE="${TIMEZONE:-UTC}"

    ask "Locale (e.g. en_GB.UTF-8) [en_US.UTF-8]:"
    read -r LOCALE
    LOCALE="${LOCALE:-en_US.UTF-8}"

    ask "Keyboard layout (e.g. gb, us) [us]:"
    read -r KB_LAYOUT
    KB_LAYOUT="${KB_LAYOUT:-us}"

    # ── Desktop ───────────────────────────────────────────────
    echo ""
    header "Desktop Settings"

    echo -e "${BOLD}Monitor setup${NC}"
    echo "  Leave blank to auto-detect (recommended for most setups)"
    ask "Primary monitor resolution (e.g. 2560x1440) [preferred]:"
    read -r MONITOR_RES
    MONITOR_RES="${MONITOR_RES:-preferred}"

    ask "Refresh rate (e.g. 165, 144, 60) [60]:"
    read -r MONITOR_HZ
    MONITOR_HZ="${MONITOR_HZ:-60}"

    ask "Monitor scale (1, 1.25, 1.5) [1]:"
    read -r MONITOR_SCALE
    MONITOR_SCALE="${MONITOR_SCALE:-1}"

    echo ""
    ask "Git name (optional) [skip]:"
    read -r GIT_NAME
    ask "Git email (optional) [skip]:"
    read -r GIT_EMAIL

    # ── GPU driver ────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}GPU Driver:${NC}"
    echo "  1) Intel (integrated — ThinkPad default)"
    echo "  2) AMD"
    echo "  3) NVIDIA"
    echo "  4) Auto-detect"
    ask "Choice [4]:"
    read -r GPU_CHOICE
    GPU_CHOICE="${GPU_CHOICE:-4}"

    # ── Summary ───────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}${CYAN}Installation Summary:${NC}"
    echo -e "  Disk       : $DISK ($FILESYSTEM)"
    echo -e "  Swap       : ${SWAP_SIZE}GB"
    echo -e "  Hostname   : $HOSTNAME"
    echo -e "  Username   : $USERNAME"
    echo -e "  Timezone   : $TIMEZONE"
    echo -e "  Locale     : $LOCALE"
    echo -e "  Keyboard   : $KB_LAYOUT"
    echo -e "  Monitor    : $MONITOR_RES @ ${MONITOR_HZ}Hz scale $MONITOR_SCALE"
    echo ""
    ask "Start installation? [Y/n]:"
    read -r START
    [[ "${START:-Y}" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

    export DISK DISK_NAME PART_SCHEME FILESYSTEM SWAP_SIZE HOSTNAME USERNAME
    export PASSWORD ROOT_PASSWORD TIMEZONE LOCALE KB_LAYOUT
    export MONITOR_RES MONITOR_HZ MONITOR_SCALE GIT_NAME GIT_EMAIL GPU_CHOICE
}

# ── Detect partition prefix ───────────────────────────────────
part() {
    if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
        echo "${DISK}p${1}"
    else
        echo "${DISK}${1}"
    fi
}

# ── Partition & format ────────────────────────────────────────
partition_disk() {
    header "Partitioning $DISK"

    # Wipe disk
    wipefs -af "$DISK" &>/dev/null
    sgdisk -Z "$DISK" &>/dev/null

    if [[ "$PART_SCHEME" == "2" && "$SWAP_SIZE" -gt 0 ]]; then
        # EFI + swap + root + home
        sgdisk -n 1:0:+1G   -t 1:ef00 -c 1:"EFI"  \
               -n 2:0:+${SWAP_SIZE}G -t 2:8200 -c 2:"swap" \
               -n 3:0:+40G  -t 3:8300 -c 3:"root" \
               -n 4:0:0     -t 4:8300 -c 4:"home" \
               "$DISK"
        EFI_PART=$(part 1); SWAP_PART=$(part 2)
        ROOT_PART=$(part 3); HOME_PART=$(part 4)
    elif [[ "$SWAP_SIZE" -gt 0 ]]; then
        # EFI + swap + root
        sgdisk -n 1:0:+1G   -t 1:ef00 -c 1:"EFI"  \
               -n 2:0:+${SWAP_SIZE}G -t 2:8200 -c 2:"swap" \
               -n 3:0:0     -t 3:8300 -c 3:"root" \
               "$DISK"
        EFI_PART=$(part 1); SWAP_PART=$(part 2); ROOT_PART=$(part 3)
    else
        # EFI + root only
        sgdisk -n 1:0:+1G   -t 1:ef00 -c 1:"EFI"  \
               -n 2:0:0     -t 2:8300 -c 2:"root" \
               "$DISK"
        EFI_PART=$(part 1); ROOT_PART=$(part 2); SWAP_PART=""
    fi

    log "Partitions created"

    # Format EFI
    mkfs.fat -F32 "$EFI_PART"
    log "EFI formatted"

    # Format swap
    if [[ -n "${SWAP_PART:-}" ]]; then
        mkswap "$SWAP_PART"
        swapon "$SWAP_PART"
        log "Swap formatted"
    fi

    # Format root
    if [[ "$FILESYSTEM" == "btrfs" ]]; then
        mkfs.btrfs -f -L root "$ROOT_PART"

        # Mount and create subvolumes
        mount "$ROOT_PART" /mnt
        btrfs subvolume create /mnt/@
        btrfs subvolume create /mnt/@home
        btrfs subvolume create /mnt/@snapshots
        btrfs subvolume create /mnt/@var_log
        umount /mnt

        # Mount subvolumes
        BTRFS_OPTS="noatime,compress=zstd,discard=async,space_cache=v2"
        mount -o "$BTRFS_OPTS,subvol=@"          "$ROOT_PART" /mnt
        mkdir -p /mnt/{home,.snapshots,var/log,boot/efi}
        mount -o "$BTRFS_OPTS,subvol=@home"      "$ROOT_PART" /mnt/home
        mount -o "$BTRFS_OPTS,subvol=@snapshots" "$ROOT_PART" /mnt/.snapshots
        mount -o "$BTRFS_OPTS,subvol=@var_log"   "$ROOT_PART" /mnt/var/log

        export BTRFS_OPTS ROOT_PART
    else
        mkfs.ext4 -F -L root "$ROOT_PART"
        mount "$ROOT_PART" /mnt
        mkdir -p /mnt/{home,boot/efi}
    fi

    # Mount home partition if separate
    if [[ -n "${HOME_PART:-}" ]]; then
        mkfs."$FILESYSTEM" -f "$HOME_PART"
        mount "$HOME_PART" /mnt/home
    fi

    # Mount EFI
    mount "$EFI_PART" /mnt/boot/efi

    log "Filesystems mounted"
    export EFI_PART ROOT_PART SWAP_PART
}

# ── Detect GPU ────────────────────────────────────────────────
detect_gpu() {
    case "$GPU_CHOICE" in
        1) GPU_PKGS="mesa intel-media-driver libva-intel-driver"
           GPU_MODULES="i915" ;;
        2) GPU_PKGS="mesa amdvlk vulkan-radeon libva-mesa-driver"
           GPU_MODULES="amdgpu" ;;
        3) GPU_PKGS="nvidia nvidia-utils nvidia-settings"
           GPU_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm" ;;
        *) # Auto-detect
           if lspci | grep -qi nvidia; then
               GPU_PKGS="nvidia nvidia-utils nvidia-settings"
               GPU_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
               info "NVIDIA GPU detected"
           elif lspci | grep -qi "amd\|radeon"; then
               GPU_PKGS="mesa amdvlk vulkan-radeon libva-mesa-driver"
               GPU_MODULES="amdgpu"
               info "AMD GPU detected"
           else
               GPU_PKGS="mesa intel-media-driver libva-intel-driver"
               GPU_MODULES="i915"
               info "Intel GPU detected"
           fi ;;
    esac
    export GPU_PKGS GPU_MODULES
}

# ── Install base system ───────────────────────────────────────
install_base() {
    header "Installing Base System"

    # Update mirrors
    step() { echo -e "${BOLD}  → $*${NC}"; }

    step "Updating mirrors..."
    reflector --country GB,US --age 12 --protocol https \
              --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || \
        warn "reflector failed — using default mirrors"

    # Base packages
    local base_pkgs=(
        base base-devel linux linux-firmware linux-headers
        "$FILESYSTEM"
        efibootmgr
        networkmanager
        git curl wget
        sudo
        zsh
        nano vim
    )

    # Add btrfs-progs if needed
    [[ "$FILESYSTEM" == "btrfs" ]] && base_pkgs+=(btrfs-progs)

    step "Installing base packages..."
    pacstrap -K /mnt "${base_pkgs[@]}"
    log "Base system installed"

    # Generate fstab
    step "Generating fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab
    log "fstab generated"
}

# ── Chroot configuration ──────────────────────────────────────
configure_system() {
    header "Configuring System"

    # Copy mirrorlist
    cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

    arch-chroot /mnt bash << CHROOT
set -e

# Timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Locale
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KB_LAYOUT" > /etc/vconsole.conf

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

# Pacman config — enable multilib and color
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm

# Root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Create user
useradd -m -G wheel,audio,video,input,storage,optical -s /bin/zsh $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Sudo
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# Mkinitcpio
sed -i 's/^MODULES=(/MODULES=($GPU_MODULES /' /etc/mkinitcpio.conf
[[ "$FILESYSTEM" == "btrfs" ]] && \
    sed -i 's/^HOOKS=(base udev/HOOKS=(base udev btrfs/' /etc/mkinitcpio.conf || true
mkinitcpio -P

# Enable NetworkManager
systemctl enable NetworkManager
systemctl enable bluetooth 2>/dev/null || true

CHROOT
    log "System configured"
}

# ── Install Limine ────────────────────────────────────────────
install_limine() {
    header "Installing Limine Bootloader"

    # Install limine in chroot
    arch-chroot /mnt bash << CHROOT
set -e

# Install limine
pacman -S --noconfirm limine

# Install to EFI
mkdir -p /boot/efi/EFI/limine
cp /usr/share/limine/BOOTX64.EFI /boot/efi/EFI/limine/

# Install limine config dir
mkdir -p /boot/limine

# Get root UUID
ROOT_UUID=\$(blkid -s UUID -o value $ROOT_PART)

# Build kernel cmdline
if [[ "$FILESYSTEM" == "btrfs" ]]; then
    CMDLINE="root=UUID=\$ROOT_UUID rootflags=subvol=@ rw rootfstype=btrfs quiet splash"
else
    CMDLINE="root=UUID=\$ROOT_UUID rw quiet splash"
fi

# Write limine.conf
cat > /boot/limine/limine.conf << EOF
timeout: 5
remember_last_entry: yes
interface_branding: $HOSTNAME
interface_branding_color: c94a1a
interface_help_color: 7a3010
wallpaper: boot():/limine/wallpaper.png
wallpaper_style: stretched
backdrop: e8dcc8

/$HOSTNAME (linux)
    protocol: efi
    path: boot():/EFI/Linux/arch-linux.efi
    cmdline: \$CMDLINE
EOF

# Register with UEFI
efibootmgr --create --disk $DISK --part 1 \
    --label "Limine" \
    --loader "\\EFI\\limine\\BOOTX64.EFI" 2>/dev/null || true

CHROOT
    log "Limine installed"
}

# ── Copy dotfiles and run installer ───────────────────────────
install_desktop() {
    header "Installing Desktop Environment"

    step "Cloning archpad dotfiles..."
    arch-chroot /mnt bash << CHROOT
set -e
cd /home/$USERNAME

# Clone the repo as the user
sudo -u $USERNAME git clone https://github.com/abdullahhassanjalil/archpad.git
chown -R $USERNAME:$USERNAME archpad

CHROOT

    # Write the desktop installer script to run in chroot as user
    cat > /mnt/home/$USERNAME/archpad/desktop-setup.sh << SETUP
#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
log()    { echo -e "\${GREEN}[✓]\${NC} \$*"; }
warn()   { echo -e "\${YELLOW}[!]\${NC} \$*"; }
step()   { echo -e "\${BOLD}  → \$*\${NC}"; }
header() { echo -e "\n\${BOLD}\${CYAN}══ \$* ══\${NC}\n"; }

DOTFILES="/home/$USERNAME/archpad/dotfiles"
LOG="/home/$USERNAME/archpad-desktop.log"

header "Installing yay"
if ! command -v yay &>/dev/null; then
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay && makepkg -si --noconfirm >> "\$LOG" 2>&1
fi
log "yay ready"

header "Installing packages"
pacman_pkgs=(
    hyprland hyprlock hypridle hyprshot
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    xdg-utils xdg-user-dirs
    wayland wayland-protocols
    qt5-wayland qt6-wayland qt5ct qt6ct
    waybar kitty rofi-wayland
    yazi ffmpegthumbnailer poppler fd ripgrep fzf zoxide imagemagick
    dunst libnotify
    ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols noto-fonts noto-fonts-emoji
    papirus-icon-theme
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol
    bluez bluez-utils blueman
    networkmanager network-manager-applet
    brightnessctl polkit-gnome
    sddm qt6-svg
    plymouth tree-sitter-cli
    neovim nodejs npm
    nwg-look adwaita-icon-theme
    git curl wget unzip tar gzip jq btop fastfetch
    $GPU_PKGS
)

aur_pkgs=(swww matugen-bin wlogout hyprpaper papirus-folders-git oh-my-zsh-git unar)

for pkg in "\${pacman_pkgs[@]}"; do
    echo -ne "  Installing \$pkg...\r"
    sudo pacman -S --needed --noconfirm "\$pkg" >> "\$LOG" 2>&1 || warn "Failed: \$pkg"
done
log "Pacman packages done"

sudo npm install -g bash-language-server >> "\$LOG" 2>&1 || true

for pkg in "\${aur_pkgs[@]}"; do
    echo -ne "  Installing \$pkg...\r"
    yay -S --needed --noconfirm "\$pkg" >> "\$LOG" 2>&1 || warn "AUR failed: \$pkg"
done
log "AUR packages done"

header "Enabling services"
sudo systemctl enable sddm
sudo systemctl enable bluetooth
sudo usermod -aG input,video,audio "$USERNAME"

# Fix SDDM PAM
sudo tee /etc/pam.d/sddm > /dev/null << 'EOF'
#%PAM-1.0
auth        include     system-login
account     include     system-login
password    include     system-login
session     include     system-login
EOF
log "Services enabled"

header "Deploying dotfiles"

# Hyprland
mkdir -p ~/.config/hypr
sed \
    -e "s/kb_layout    = \"gb\"/kb_layout    = \"$KB_LAYOUT\"/" \
    -e "s/mode     = \"preferred\"/mode     = \"$MONITOR_RES\"/" \
    -e "s/scale    = 1/scale    = $MONITOR_SCALE/" \
    "\$DOTFILES/hypr/hyprland.lua" > ~/.config/hypr/hyprland.lua
cp "\$DOTFILES/hypr/hyprlock.conf"     ~/.config/hypr/
cp "\$DOTFILES/hypr/colors.lua"        ~/.config/hypr/
cp "\$DOTFILES/hypr/wallpaper.sh"      ~/.config/hypr/
cp "\$DOTFILES/hypr/keybinds-popup.sh" ~/.config/hypr/
chmod +x ~/.config/hypr/wallpaper.sh ~/.config/hypr/keybinds-popup.sh
log "Hyprland"

# Waybar
mkdir -p ~/.config/waybar
cp "\$DOTFILES/waybar/config.jsonc" ~/.config/waybar/
cp "\$DOTFILES/waybar/style.css"    ~/.config/waybar/
log "Waybar"

# Rofi
mkdir -p ~/.config/rofi
cp "\$DOTFILES/rofi/config.rasi" ~/.config/rofi/
cp "\$DOTFILES/rofi/theme.rasi"  ~/.config/rofi/
log "Rofi"

# Kitty
mkdir -p ~/.config/kitty
cp "\$DOTFILES/kitty/kitty.conf" ~/.config/kitty/
touch ~/.config/kitty/colors.conf
log "Kitty"

# Dunst
mkdir -p ~/.config/dunst
cp "\$DOTFILES/dunst/dunstrc" ~/.config/dunst/
log "Dunst"

# Wlogout
mkdir -p ~/.config/wlogout
cp "\$DOTFILES/wlogout/layout"    ~/.config/wlogout/
cp "\$DOTFILES/wlogout/style.css" ~/.config/wlogout/
log "Wlogout"

# Matugen
mkdir -p ~/.config/matugen/templates
cp "\$DOTFILES/matugen/config.toml" ~/.config/matugen/
cp "\$DOTFILES/matugen/templates/"* ~/.config/matugen/templates/
log "Matugen"

# GTK
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
cp "\$DOTFILES/gtk-3.0/gtk.css" ~/.config/gtk-3.0/
cp "\$DOTFILES/gtk-4.0/gtk.css" ~/.config/gtk-4.0/
touch ~/.config/gtk-3.0/colors.css ~/.config/gtk-4.0/colors.css
log "GTK"

# Neovim
mkdir -p ~/.config/nvim/lua/{core,plugins,themes} ~/.config/nvim/colors
cp "\$DOTFILES/nvim/init.lua"                      ~/.config/nvim/
cp "\$DOTFILES/nvim/lua/core/options.lua"          ~/.config/nvim/lua/core/
cp "\$DOTFILES/nvim/lua/core/keymaps.lua"          ~/.config/nvim/lua/core/
cp "\$DOTFILES/nvim/lua/core/autocmds.lua"         ~/.config/nvim/lua/core/
cp "\$DOTFILES/nvim/lua/plugins/init.lua"          ~/.config/nvim/lua/plugins/
cp "\$DOTFILES/nvim/colors/matugen.lua"            ~/.config/nvim/colors/
cp "\$DOTFILES/nvim/lua/themes/matugen_colors.lua" ~/.config/nvim/lua/themes/
log "Neovim"

# Fastfetch
mkdir -p ~/.config/fastfetch
cp "\$DOTFILES/fastfetch/config.jsonc" ~/.config/fastfetch/ 2>/dev/null || true
cp "\$DOTFILES/fastfetch/archpad.txt"  ~/.config/fastfetch/ 2>/dev/null || true
log "Fastfetch"

# SDDM
sudo mkdir -p /usr/share/sddm/themes/retro-warm
sudo cp "\$DOTFILES/sddm-retro/Main.qml"        /usr/share/sddm/themes/retro-warm/
sudo cp "\$DOTFILES/sddm-retro/theme.conf"       /usr/share/sddm/themes/retro-warm/
sudo cp "\$DOTFILES/sddm-retro/metadata.desktop" /usr/share/sddm/themes/retro-warm/
[[ -f "\$DOTFILES/wallpaper/default.png" ]] && \
    sudo cp "\$DOTFILES/wallpaper/default.png" \
            /usr/share/sddm/themes/retro-warm/background.png
printf '[Theme]\nCurrent=retro-warm\n' | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null
log "SDDM"

# Plymouth
if [[ -d "\$DOTFILES/plymouth" ]]; then
    sudo mkdir -p /usr/share/plymouth/themes/retro-warm
    sudo cp "\$DOTFILES/plymouth/"* /usr/share/plymouth/themes/retro-warm/
    sudo plymouth-set-default-theme retro-warm >> "\$LOG" 2>&1 || true
    log "Plymouth"
fi

# Helper scripts
sudo tee /usr/local/bin/sddm-set-wallpaper > /dev/null << 'SCRIPT'
#!/bin/bash
[[ -n "\$1" ]] && cp "\$1" /usr/share/sddm/themes/retro-warm/background.png && \
    chmod 644 /usr/share/sddm/themes/retro-warm/background.png
CONF="/home/\${SUDO_USER}/.config/matugen/sddm-theme-generated.conf"
[[ -f "\$CONF" ]] && cp "\$CONF" /usr/share/sddm/themes/retro-warm/theme.conf
SCRIPT
sudo chmod 755 /usr/local/bin/sddm-set-wallpaper

sudo tee /usr/local/bin/limine-set-theme > /dev/null << 'SCRIPT'
#!/bin/bash
[[ -f "\$1" ]] && cp "\$1" /boot/limine/wallpaper.png
[[ -f /boot/limine/limine.conf ]] && {
    sed -i "s/interface_branding_color:.*/interface_branding_color: \$2/" /boot/limine/limine.conf
    sed -i "s/interface_help_color:.*/interface_help_color: \$3/"         /boot/limine/limine.conf
}
SCRIPT
sudo chmod 755 /usr/local/bin/limine-set-theme

printf '%s ALL=(ALL) NOPASSWD: /usr/local/bin/sddm-set-wallpaper\n' "$USERNAME" \
    | sudo tee /etc/sudoers.d/sddm-wallpaper > /dev/null
printf '%s ALL=(ALL) NOPASSWD: /usr/local/bin/limine-set-theme\n' "$USERNAME" \
    | sudo tee /etc/sudoers.d/limine-theme > /dev/null
sudo chmod 440 /etc/sudoers.d/sddm-wallpaper /etc/sudoers.d/limine-theme

# XDG
xdg-user-dirs-update 2>/dev/null || true
mkdir -p ~/Pictures/Wallpapers ~/Pictures/Screenshots

# Wallpaper
[[ -f "\$DOTFILES/wallpaper/default.png" ]] && \
    cp "\$DOTFILES/wallpaper/default.png" ~/Pictures/Wallpapers/default.png

# Zshrc
cat > ~/.zshrc << 'ZSHRC'
# ARCHPAD zshrc
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Instant prompt
if [[ -r "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh" ]]; then
    source "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh"
fi

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
[[ -f \$ZSH/oh-my-zsh.sh ]] && source \$ZSH/oh-my-zsh.sh

export PATH="\$HOME/.cargo/bin:\$HOME/.local/bin:\$PATH"
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# System info
fastfetch
ZSHRC

# Git config
[[ -n "$GIT_NAME"  ]] && git config --global user.name  "$GIT_NAME"
[[ -n "$GIT_EMAIL" ]] && git config --global user.email "$GIT_EMAIL"

# XDG portal
mkdir -p ~/.config/xdg-desktop-portal
cat > ~/.config/xdg-desktop-portal/hyprland-portals.conf << 'EOF'
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Settings=gtk
EOF

log "All dotfiles deployed"

header "Finalising"
sudo timedatectl set-timezone "$TIMEZONE" 2>/dev/null || true
sudo timedatectl set-ntp true 2>/dev/null || true
papirus-folders -C orange --theme Papirus-Dark 2>/dev/null || true

# Neovim plugins
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

echo ""
echo -e "\${GREEN}\${BOLD}Desktop setup complete!\${NC}"
SETUP

    chmod +x /mnt/home/$USERNAME/archpad/desktop-setup.sh
    chown $USERNAME:$USERNAME /mnt/home/$USERNAME/archpad/desktop-setup.sh

    # Run as user in chroot
    arch-chroot /mnt sudo -u $USERNAME bash /home/$USERNAME/archpad/desktop-setup.sh

    log "Desktop installed"
}

# ── Plymouth initramfs ────────────────────────────────────────
finalise() {
    header "Finalising"

    arch-chroot /mnt bash << CHROOT
set -e

# Rebuild initramfs with plymouth
if grep -q "plymouth" /etc/mkinitcpio.conf 2>/dev/null; then
    plymouth-set-default-theme retro-warm 2>/dev/null || true
fi
mkinitcpio -P

# Add quiet splash to kernel cmdline
if [[ -f /etc/kernel/cmdline ]]; then
    grep -q "quiet splash" /etc/kernel/cmdline || \
        printf '%s quiet splash' "\$(cat /etc/kernel/cmdline)" \
        | tee /etc/kernel/cmdline > /dev/null
fi

CHROOT
    log "Initramfs rebuilt"
}

# ── Unmount ───────────────────────────────────────────────────
cleanup() {
    header "Cleaning Up"
    umount -R /mnt 2>/dev/null || true
    swapoff -a 2>/dev/null || true
    log "Unmounted"
}

# ── Summary ───────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${BOLD}${GREEN}╔══════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║   ARCHPAD Installation Complete! 🎉   ║${NC}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}System:${NC}"
    echo -e "  Hostname  : $HOSTNAME"
    echo -e "  Username  : $USERNAME"
    echo -e "  Disk      : $DISK ($FILESYSTEM)"
    echo -e "  Bootloader: Limine"
    echo ""
    echo -e "  ${BOLD}Desktop:${NC}"
    echo -e "  • Hyprland 0.55  • Waybar    • Kitty"
    echo -e "  • Neovim + LSP   • Rofi      • yazi"
    echo -e "  • SDDM theme     • Plymouth  • matugen"
    echo -e "  • wlogout        • Dunst     • fastfetch"
    echo ""
    echo -e "  ${BOLD}First login:${NC}"
    echo -e "  Change wallpaper with SUPER+W to apply theme"
    echo -e "  Run p10k configure for prompt setup"
    echo ""
    echo -e "  ${YELLOW}Remove installation media before rebooting!${NC}"
    echo ""
    read -rp "  Reboot now? [Y/n]: " REBOOT
    [[ "${REBOOT:-Y}" =~ ^[Yy]$ ]] && reboot
}

# ── Main ──────────────────────────────────────────────────────
main() {
    print_banner
    preflight
    configure
    detect_gpu
    partition_disk
    install_base
    configure_system
    install_limine
    install_desktop
    finalise
    cleanup
    print_summary
}

main "$@"
