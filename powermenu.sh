#!/bin/bash

export GDK_BACKEND=wayland
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export WAYLAND_DISPLAY="wayland-0"

choice=$(echo -e " Shutdown\n Reboot\n Hibernate\n Logout" | \
    wofi --show dmenu --prompt "Power")

case $choice in
    " Shutdown") systemctl poweroff ;;
    " Reboot") systemctl reboot ;;
    " Hibernate") systemctl hibernate ;;
    " Logout") gnome-session-quit --logout --no-prompt ;;
esac
