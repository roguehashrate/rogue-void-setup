#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Please run this script as root."
  exit 1
fi

echo "[*] Updating repositories..."
xbps-install -Suy

USER_NAME=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1; exit}' /etc/passwd)
if [ -z "$USER_NAME" ]; then
  echo "❌ Could not detect a normal user."
  exit 1
fi

echo "[*] Installing doas..."
xbps-install -y opendoas

if [ ! -f /etc/doas.conf ]; then
  echo "permit persist :wheel" > /etc/doas.conf
  chmod 0400 /etc/doas.conf
fi

usermod -aG wheel "$USER_NAME"

echo "[*] Installing packages..."
xbps-install -y \
  dbus \
  elogind \
  xorg \
  gnome \
  gnome-apps \
  wayland \
  wayland-devel \
  wayland-protocols

echo "[*] Linking services..."
doas ln -s /etc/sv/dbus /var/service
doas ln -s /etc/sv/elogind /var/service
doas ln -s /etc/sv/gdm /var/service

# Add sudo alias to remind user to use doas
USER_BASHRC="/home/$USER_NAME/.bashrc"
touch "$USER_BASHRC"
if ! grep -q '^alias sudo=' "$USER_BASHRC"; then
  echo "alias sudo='echo \"Please try again and use doas.\"'" >> "$USER_BASHRC"
fi

echo
echo "[✓] Done, everything is installed and linked, reboot."
