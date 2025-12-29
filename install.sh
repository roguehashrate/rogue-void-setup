#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "[*] Updating system..."
xbps-install -uy xbps
xbps-install -uy

echo "[*] Enabling non-free repository..."
xbps-install -Rsy void-repo-nonfree

USER_NAME=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1; exit}' /etc/passwd)
if [ -z "$USER_NAME" ]; then
  echo "Could not detect a normal user."
  exit 1
fi

echo "[*] Installing base utilities and dev tools..."
xbps-install -y \
  curl wget git xz unzip zip nano vim \
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
  efibootmgr zsh

echo "[*] Installing GNOME (Wayland default)..."
xbps-install -y \
  xorg \
  gnome-shell \
  gnome-control-center \
  gnome-session \
  gdm \
  gnome-terminal \
  nautilus \
  gnome-tweaks \
  evince

xbps-install -Rsy \
  xdg-desktop-portal \
  xdg-desktop-portal-gtk \
  xdg-user-dirs \
  xdg-user-dirs-gtk \
  xdg-utils \
  gnome-browser-connector

echo "[*] Installing networking, audio, printing, bluetooth..."
xbps-install -y \
  dbus elogind \
  NetworkManager \
  NetworkManager-openvpn \
  NetworkManager-openconnect \
  NetworkManager-vpnc \
  NetworkManager-l2tp \
  pipewire wireplumber \
  bluez \
  cups cups-pk-helper cups-filters \
  foomatic-db foomatic-db-engine gutenprint

usermod -aG bluetooth "$USER_NAME"

echo "[*] Installing laptop power & time services..."
xbps-install -y \
  cronie chrony \
  tlp tlp-rdw \
  powertop

echo "[*] Installing fonts..."
xbps-install -Rsy \
  noto-fonts-emoji \
  noto-fonts-ttf \
  noto-fonts-ttf-extra \
  noto-fonts-cjk \
  font-liberation-ttf \
  font-firacode \
  font-fira-ttf \
  font-awesome \
  dejavu-fonts-ttf \
  font-hack-ttf \
  ttf-ubuntu-font-family

echo "[*] Installing Intel graphics stack (ThinkPad T470)..."
xbps-install -y \
  linux-firmware-intel \
  mesa mesa-dri \
  vulkan-loader \
  mesa-vulkan-intel \
  mesa-vaapi \
  mesa-vdpau

echo "[*] Optional theming..."
xbps-install -y papirus-icon-theme breeze-cursors || true

echo "[*] Optional Flatpak support..."
xbps-install -y flatpak || true

echo "[*] Enabling services..."
ln -sf /etc/sv/dbus /var/service
ln -sf /etc/sv/elogind /var/service
ln -sf /etc/sv/gdm /var/service
ln -sf /etc/sv/NetworkManager /var/service
ln -sf /etc/sv/bluetoothd /var/service
ln -sf /etc/sv/cupsd /var/service
ln -sf /etc/sv/cronie /var/service
ln -sf /etc/sv/chronyd /var/service
ln -sf /etc/sv/tlp /var/service

echo "[*] Disabling conflicting services..."
rm -f /var/service/acpid || true
rm -f /var/service/dhcpcd || true

echo "[*] Adding sudo reminder alias..."
USER_BASHRC="/home/$USER_NAME/.bashrc"
touch "$USER_BASHRC"
if ! grep -q '^alias sudo=' "$USER_BASHRC"; then
  echo "alias sudo='echo \"Please try again and use doas.\"'" >> "$USER_BASHRC"
fi

echo
echo "Done. Everything is installed and linked. Reboot."
