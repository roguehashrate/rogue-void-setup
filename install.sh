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
xbps-install -S

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
# Flatpak + Flathub
# ------------------------------------------------------------
echo "[*] Installing Flatpak and portals..."
xbps-install -y flatpak xdg-desktop-portal xdg-desktop-portal-gtk \
                gnome-software gnome-software-plugin-flatpak

mkdir -p /var/lib/flatpak

echo "[*] Adding Flathub..."
flatpak remote-add --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo

# ------------------------------------------------------------
# Audio + Bluetooth (PipeWire)
# ------------------------------------------------------------
echo "[*] Installing PipeWire and Bluetooth..."
xbps-install -y pipewire pipewire-pulse wireplumber \
                bluez gnome-bluetooth

ln -sf /etc/sv/bluetoothd /var/service/

# ------------------------------------------------------------
# Optional software selections
# ------------------------------------------------------------

echo
echo "[*] Optional: Install Web Browser?"
echo "1) Firefox (Flatpak)"
echo "2) Brave (Flatpak)"
echo "3) Zen Browser (Flatpak)"
echo "4) None"
printf "Enter choice [1-4]: "
read opt
case "$opt" in
  1) flatpak install -y flathub org.mozilla.firefox ;;
  2) flatpak install -y flathub com.brave.Browser ;;
  3) flatpak install -y flathub app.zen_browser.zen ;;
esac

echo
echo "[*] Optional: Install Text Editor?"
echo "1) Vim"
echo "2) Neovim"
echo "3) Emacs"
echo "4) Nano"
echo "5) Micro"
echo "6) None"
printf "Enter choice [1-6]: "
read opt
case "$opt" in
  1) xbps-install -y vim ;;
  2) xbps-install -y neovim ;;
  3) xbps-install -y emacs ;;
  4) xbps-install -y nano ;;
  5) xbps-install -y micro ;;
esac

echo
echo "[*] Optional: Install Terminal Emulator?"
echo "1) Alacritty"
echo "2) Kitty"
echo "3) None"
printf "Enter choice [1-3]: "
read opt
case "$opt" in
  1) xbps-install -y alacritty ;;
  2) xbps-install -y kitty ;;
esac

echo
echo "[*] Optional: Install Image Manipulation Tool?"
echo "1) GIMP (Flatpak)"
echo "2) Krita (Flatpak)"
echo "3) None"
printf "Enter choice [1-3]: "
read opt
case "$opt" in
  1) flatpak install -y flathub org.gimp.GIMP ;;
  2) flatpak install -y flathub org.kde.krita ;;
esac

echo
echo "[*] Optional: Install OBS Studio (Flatpak)?"
echo "1) Yes"
echo "2) No"
printf "Enter choice [1-2]: "
read opt
case "$opt" in
  1) flatpak install -y flathub com.obsproject.Studio ;;
esac

# ------------------------------------------------------------
# Finish
# ------------------------------------------------------------
echo
echo "[✓] Setup complete!"
echo "➡ Reboot now."
echo "➡ Log in to GNOME."
echo "➡ Use: doas <command>"
