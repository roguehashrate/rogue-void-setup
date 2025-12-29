#!/bin/bash
set -euo pipefail

apps=(
"epiphany|GNOME Web (Epiphany) - Default GNOME web browser"
"gnome-maps|GNOME Maps - Maps and navigation app"
"gnome-photos|GNOME Photos - Photo viewer and organizer"
"gnome-tour|GNOME Tour - First-run GNOME introduction"
"gnome-music|GNOME Music - Music player"
"gnome-calendar|GNOME Calendar - Calendar application"
"gnome-boxes|GNOME Boxes - Virtual machines and remote systems"
"gnome-connections|GNOME Connections - Remote desktop (RDP/VNC)"
"gnome-dictionary|GNOME Dictionary - Dictionary lookup tool"
"gnome-clocks|GNOME Clocks - World clocks, alarms, timers"
"gnome-characters|GNOME Characters - Emoji and special character picker"
"polari|Polari - IRC chat client"
"totem|Videos (Totem) - Video player"
"simple-scan|Simple Scan - Document scanner app"
"gnote|Gnote - Note-taking application"
"rygel|Rygel - DLNA/UPnP media server"
"vino|Vino - Legacy VNC screen sharing server"
"devhelp|Devhelp - Developer API documentation browser"
"ghex|GHex - Hex editor"
"gitg|gitg - Graphical Git repository viewer"
"decibels|Decibels - Audio waveform and level analysis tool"
)

echo "This script lets you remove OPTIONAL GNOME applications."
echo "Nothing here is required for GNOME Shell or the desktop to work."

for entry in "${apps[@]}"; do
    IFS="|" read -r pkg desc <<< "$entry"

    if ! xbps-query -Rs "^${pkg}$" >/dev/null 2>&1; then
        continue
    fi

    echo
    echo "Package: $pkg"
    echo "What it is: $desc"

    read -rp "Remove this application? [y/N]: " ans
    case "$ans" in
        y|Y)
            doas xbps-remove -y "$pkg"
            ;;
        *)
            echo "Keeping $pkg"
            ;;
    esac
done

echo
echo "GNOME debloating complete."