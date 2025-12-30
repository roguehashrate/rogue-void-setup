#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "[*] Updating system..."
xbps-install -Suy xbps || true
xbps-install -Suy || true

echo "[*] Enabling non-free repository..."
xbps-install -Rsy void-repo-nonfree || true

USER_NAME=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1; exit}' /etc/passwd)
if [ -z "$USER_NAME" ]; then
  echo "Could not detect a normal user."
  exit 1
fi
echo "[*] Detected user: $USER_NAME"

echo "[*] Installing doas..."
xbps-install -y opendoas
if [ ! -f /etc/doas.conf ]; then
  echo "permit persist :wheel" > /etc/doas.conf
  chmod 0400 /etc/doas.conf
fi
usermod -aG wheel "$USER_NAME"

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

echo "[*] Installing GNOME desktop..."
xbps-install -y \
  xorg \
  gnome-shell \
  gnome-control-center \
  gnome-session \
  gdm \
  gnome-terminal \
  nautilus \
  gnome-tweaks \
  evince \
  gnome-bluetooth

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

usermod -aG bluetooth lp "$USER_NAME"

echo "[*] Installing laptop power & time services..."
xbps-install -y cronie chrony tlp tlp-rdw powertop

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

echo "[*] Installing Intel graphics stack..."
xbps-install -y \
  linux-firmware-intel \
  mesa mesa-dri \
  vulkan-loader \
  mesa-vulkan-intel \
  mesa-vaapi \
  mesa-vdpau

echo "[*] Installing Flatpak..."
xbps-install -y flatpak || true
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "[*] Enabling services..."
for svc in dbus elogind gdm NetworkManager bluetoothd cupsd cronie chronyd tlp pipewire wireplumber; do
  ln -sf "/etc/sv/$svc" /var/service/
done

echo "[*] Disabling conflicting services..."
for svc in acpid dhcpcd; do
  rm -f "/var/service/$svc" || true
done

echo "[*] Adding sudo reminder alias..."
USER_BASHRC="/home/$USER_NAME/.bashrc"
touch "$USER_BASHRC"
if ! grep -q '^alias sudo=' "$USER_BASHRC"; then
  echo "alias sudo='echo \"Please try again and use doas.\"'" >> "$USER_BASHRC"
fi

echo "[*] Verifying essential services..."
for svc in pipewire wireplumber NetworkManager bluetoothd cupsd tlp chronyd gdm; do
    if sv status "$svc" | grep -q run; then
        echo "  $svc ✅ running"
    else
        echo "  $svc ❌ NOT running"
    fi
done

echo
echo "✅ Setup complete! Reboot to start using your fully functional Void Linux GNOME laptop."
