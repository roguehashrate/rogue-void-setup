#!/bin/sh
set -eu

# ------------------------------------------------------------
# Root check
# ------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Please run this script as root."
  exit 1
fi

echo "[*] Updating repositories..."
xbps-install -Suvy

# ------------------------------------------------------------
# Detect primary user (UID >= 1000)
# ------------------------------------------------------------
USER_NAME=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1; exit}' /etc/passwd)
if [ -z "$USER_NAME" ]; then
  echo "❌ Could not detect a normal user."
  exit 1
fi
echo "[*] Detected user: $USER_NAME"

# ------------------------------------------------------------
# doas setup
# ------------------------------------------------------------
echo "[*] Installing doas..."
xbps-install -y opendoas
if [ ! -f /etc/doas.conf ]; then
  echo "permit persist :wheel" > /etc/doas.conf
  chmod 0400 /etc/doas.conf
fi
usermod -aG wheel "$USER_NAME"

# sudo alias reminder
su - "$USER_NAME" -c '
SHELL_RC="$HOME/.bashrc"
touch "$SHELL_RC"
if ! grep -q "alias sudo=" "$SHELL_RC"; then
  echo "alias sudo='\''echo \"Use doas instead of sudo\"'\''" >> "$SHELL_RC"
fi
'

# ------------------------------------------------------------
# GNOME + GDM
# ------------------------------------------------------------
echo "[*] Installing GNOME and GDM..."
xbps-install -y gnome gdm
ln -sf /etc/sv/gdm /var/service/
sv up gdm

# ------------------------------------------------------------
# VM video driver (QEMU/Boxes)
# ------------------------------------------------------------
echo "[*] Installing VM video driver..."
xbps-install -y xf86-video-qxl

# ------------------------------------------------------------
# PipeWire + Bluetooth
# ------------------------------------------------------------
echo "[*] Installing PipeWire + Bluetooth..."
xbps-install -y pipewire wireplumber bluez gnome-bluetooth
ln -sf /etc/sv/bluetoothd /var/service/
sv up bluetoothd

# ------------------------------------------------------------
# Finish
# ------------------------------------------------------------
echo
echo "[✓] Full desktop setup complete!"
echo "➡ Reboot now to enter GNOME with full audio, Bluetooth, doas, and all apps ready."
