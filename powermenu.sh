#!/bin/bash

WLR_NO_HARDWARE_CURSORS=1 rofi_cmd="rofi -dmenu -i -no-custom -p -fullscreen -theme ./powermenu.rasi"

# Main menu
main_menu() {
    echo -e "󰜉 Reboot\n Power Off\n󰒲 Hibernate" | $rofi_cmd "Power Menu"
}

# Reboot submenu
reboot_menu() {
    choice=$(echo -e "󰭜 Back\n󰜉 Reboot" | $rofi_cmd "Reboot?")
    case $choice in
        "󰭜 Back") main ;;              # back to main
        "󰜉 Reboot") systemctl reboot ;;
    esac
}

# Poweroff submenu
poweroff_menu() {
    choice=$(echo -e "󰭜 Back\n Power Off" | $rofi_cmd "Power Off?")
    case $choice in
        "󰭜 Back") main ;;
        " Power Off") systemctl poweroff ;;
    esac
}

# Hibernate submenu
hibernate_menu() {
    choice=$(echo -e "󰭜 Back\n󰒲 Hibernate" | $rofi_cmd "Hibernate?")
    case $choice in
        "󰭜 Back") main ;;
        "󰒲 Hibernate") systemctl hibernate ;;
    esac
}

# Entry point
main() {
    choice=$(main_menu)
    case $choice in
        "󰜉 Reboot") reboot_menu ;;
        " Power Off") poweroff_menu ;;
        "󰒲 Hibernate") hibernate_menu ;;
    esac
}

main
