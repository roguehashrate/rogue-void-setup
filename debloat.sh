#!/bin/sh
set -eu

echo "[*] This script will help you remove optional GNOME apps without breaking the desktop."

declare -A GNOME_APPS
GNOME_APPS=(
  ["gnome-maps"]="GNOME Maps - Map viewer and navigation"
  ["gnome-photos"]="GNOME Photos - Photo viewer and organizer"
  ["gnome-tour"]="GNOME Tour - Introduction/tutorial for GNOME"
  ["epiphany"]="Web Browser - GNOME Web (Epiphany)"
  ["gnome-builder"]="GNOME Builder - IDE for GNOME app development"
  ["devhelp"]="Devhelp - API documentation browser"
  ["gnome-contacts"]="GNOME Contacts - Manage contacts"
  ["gnome-music"]="GNOME Music - Music player"
  ["gnome-calendar"]="GNOME Calendar - Calendar application"
  ["gnome-boxes"]="GNOME Boxes - Virtual machine manager"
  ["gnome-connections"]="GNOME Connections - Remote desktop client"
  ["gnome-dictionary"]="GNOME Dictionary - Lookup words and definitions"
  ["gnome-clocks"]="GNOME Clocks - Alarm, world clock, timer, stopwatch"
  ["gnome-characters"]="GNOME Characters - Browse characters and emojis"
  ["polari"]="Polari - IRC client"
  ["totem"]="Totem - Video player"
  ["simple-scan"]="Simple Scan - Document scanner"
  ["vino"]="Vino - VNC server"
  ["gnote"]="Gnote - Note-taking app"
  ["rygel"]="Rygel - Media server"
  ["ghex"]="GHex - Hex editor"
  ["gitg"]="Git GUI - GUI for Git repositories"
  ["decibles"]="Decibles - Audio analysis tool"
  ["biliben"]="Biliben - GNOME benchmarking tool"
  ["endeavouros-gui"]="Endeavour GUI tools (Void/Endeavour specific)"
)

for app in "${!GNOME_APPS[@]}"; do
    echo
    echo "App: $app"
    echo "Description: ${GNOME_APPS[$app]}"
    while true; do
        printf "Do you want to remove it? [y/n]: "
        read ans
        case "$ans" in
            [Yy]* )
                echo "Removing $app..."
                doas xbps-remove -y "$app"
                break
                ;;
            [Nn]* )
                echo "Skipping $app..."
                break
                ;;
            * )
                echo "Please answer y (yes) or n (no)."
                ;;
        esac
    done
done

echo
echo "[✓] Debloating complete."
