#!/bin/sh
set -eu

# ------------------------------------------------------------
# Root check
# ------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Please run this script as root."
  exit 1
fi

echo "[*] Syncing XBPS repositories..."
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
  echo "[*] Configuring doas..."
  echo "permit persist :wheel" > /etc/doas.conf
  chmod 0400 /etc/doas.conf
fi

echo "[*] Ensuring user is in wheel group..."
usermod -aG wheel "$USER_NAME"

# Add sudo reminder alias
echo "[*] Adding sudo alias reminder..."
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
if ! command -v gnome-shell >/dev/null 2>&1; then
  echo "[*] Installing GNOME and GDM..."
  xbps-install -y gnome gdm
  ln -sf /etc/sv/gdm /var/service/
else
  echo "[*] GNOME already installed — skipping."
fi

# ------------------------------------------------------------
# Flatpak (commented out for now)
# ------------------------------------------------------------
# echo "[*] Installing Flatpak and portals..."
# xbps-install -y flatpak xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome
# mkdir -p /var/lib/flatpak
# flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# ------------------------------------------------------------
# PipeWire + Bluetooth (Void-correct packages)
# ------------------------------------------------------------
xbps-install -y pipewire wireplumber pipewire-alsa pipewire-pulseaudio \
               bluez gnome-bluetooth

ln -sf /etc/sv/bluetoothd /var/service/

# ------------------------------------------------------------
# Optional software selections (commented out for now)
# ------------------------------------------------------------
# echo
# echo "[*] Optional: Install Web Browser?"
# ...
# echo "[*] Optional: Install Text Editor?"
# ...
# echo "[*] Optional: Install Terminal Emulator?"
# ...
# echo "[*] Optional: Install Image Manipulation Tool?"
# ...
# echo "[*] Optional: Install OBS Studio (Flatpak)?"
# ...

# ------------------------------------------------------------
# Finish
# ------------------------------------------------------------
echo
echo "[✓] Core setup complete!"
echo "➡ Reboot now."
