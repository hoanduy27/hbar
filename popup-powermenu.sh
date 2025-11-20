#!/bin/sh

case "$1" in
    --popup)
        yad=$(yad --class power --width 300 --entry --undecorated --title "System Logout" --image=gnome-shutdown --text "Sukoshi yasumimashou~"  --button="Oops"\!gtk-cancel:1    --button="Proceed"\!gtk-ok:0 --entry-text " Shutdown" "󰜉 Reboot" "󰒲 Suspend" "󰈆 Logout" " Lock")

        case "$yad" in
            " Shutdown")
                systemctl poweroff
                ;;
            "󰜉 Reboot")
                systemctl  reboot
                ;;
            "󰒲 Suspend")
                systemctl hibernate
                ;;
            "󰈆 Logout")
                loginctl kill-user $(whoami)
                ;;
            " Lock")
                betterlockscreen -l dimblur
                ;;
        esac
        ;;
    *)
        echo "⏻"
        ;;
esac