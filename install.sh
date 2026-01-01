#!/bin/sh
set -eu

LOG="/var/log/void-installer.log"
exec > >(tee -a "$LOG") 2>&1

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "[*] Updating system..."
xbps-install -Suy

echo "[*] Enabling non-free repository..."
xbps-install -Sy void-repo-nonfree

users=($(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd))
if [ ${#users[@]} -eq 1 ]; then
    USER_NAME="${users[0]}"
else
    echo "Multiple normal users detected: ${users[*]}"
    read -rp "Which user should be configured? " USER_NAME
fi
echo "[*] Detected user: $USER_NAME"

install_doas() {
  echo "[*] Installing doas..."
  xbps-install -y opendoas
  if [ ! -f /etc/doas.conf ]; then
    echo "permit persist :wheel" > /etc/doas.conf
    chmod 0400 /etc/doas.conf
  fi
  usermod -aG wheel "$USER_NAME"
}

install_core_packages() {
  echo "[*] Installing base utilities, dev tools, and audio..."
  xbps-install -y \
    curl wget git xz unzip zip nano vim zsh \
    gptfdisk gparted xtools mtools mlocate \
    ntfs-3g fuse-exfat bash-completion \
    linux-headers htop \
    autoconf automake bison m4 make libtool flex \
    meson ninja pkg-config gcc go \
    ffmpeg optipng sassc \
    gtksourceview4 \
    json-glib json-glib-devel \
    gvfs-smb samba gvfs-goa gvfs-gphoto2 gvfs-mtp gvfs-afc gvfs-afp \
    libfido2 ykclient libyubikey pam-u2f \
    efibootmgr \
    pipewire pipewire-pulse wireplumber \
    bluez bluez-utils
}

install_gnome() {
  echo "[*] Installing GNOME desktop..."
  xbps-install -y \
    xorg gnome-shell gnome-control-center gnome-session gdm \
    gnome-terminal nautilus gnome-tweaks evince gnome-bluetooth
  xbps-install -Sy \
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-user-dirs \
    xdg-user-dirs-gtk xdg-utils gnome-browser-connector
}

install_fonts() {
  echo "[*] Installing fonts..."
  xbps-install -Sy \
    noto-fonts-emoji noto-fonts-ttf noto-fonts-ttf-extra noto-fonts-cjk \
    font-liberation-ttf font-firacode font-fira-ttf font-awesome \
    dejavu-fonts-ttf font-hack-ttf ttf-ubuntu-font-family || true
}

install_intel_graphics() {
  echo "[*] Installing Intel graphics stack..."
  xbps-install -y \
    linux-firmware-intel mesa mesa-dri \
    vulkan-loader mesa-vulkan-intel \
    mesa-vaapi mesa-vdpau
}

enable_services() {
  echo "[*] Enabling essential services..."
  for svc in dbus elogind gdm NetworkManager bluetooth cupsd cronie chronyd tlp pipewire wireplumber; do
    if [ -d "/etc/sv/$svc" ]; then
      ln -sf "/etc/sv/$svc" /var/service/
    else
      echo "[!] Service $svc not found, skipping..."
    fi
  done
}

disable_conflicts() {
  echo "[*] Disabling conflicting services..."
  for svc in acpid dhcpcd; do
    rm -f "/var/service/$svc" || true
  done
}

add_sudo_alias() {
  echo "[*] Adding sudo reminder alias..."
  for file in /home/$USER_NAME/.bashrc /home/$USER_NAME/.zshrc; do
    touch "$file"
    if ! grep -q '^alias sudo=' "$file"; then
      echo "alias sudo='echo \"Please try again and use doas.\"'" >> "$file"
    fi
  done
}

set_zsh_as_shell() {
  echo "[*] Setting zsh as default shell for $USER_NAME..."
  if ! grep -q "^/bin/zsh$" /etc/shells; then
    echo "/bin/zsh" >> /etc/shells
  fi
  chsh -s /bin/zsh "$USER_NAME"
}

configure_audio_bluetooth() {
  echo "[*] Configuring audio and Bluetooth..."
  usermod -aG audio,bluetooth "$USER_NAME"
  sv restart pipewire || true
  sv restart wireplumber || true
  sv restart bluetooth || true
}

verify_services() {
  echo "[*] Verifying essential services..."
  for svc in pipewire wireplumber NetworkManager bluetooth cupsd tlp chronyd gdm; do
    if sv status "$svc" 2>/dev/null | grep -q run; then
      echo "  $svc ✅ running"
    else
      echo "  $svc ❌ NOT running"
    fi
  done
}

install_doas
install_core_packages
install_gnome
install_fonts
install_intel_graphics
enable_services
disable_conflicts
add_sudo_alias
set_zsh_as_shell
configure_audio_bluetooth
verify_services

echo "[*] Void Linux setup complete! Rebooting now..."
reboot
