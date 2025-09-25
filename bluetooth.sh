#!/bin/sh

bluetooth_print() {
    bluetoothctl | while read -r REPLY; do
        if [ "$(systemctl is-active "bluetooth.service")" = "active" ]; then
            if bluetoothctl show | grep -q "Powered: yes"; then
                device_info=$(bluetoothctl info "$device")
                if echo "$device_info" | grep -q "Connected: yes"; then
                    device_alias=$(echo "$device_info" | grep "Alias" | cut -d ' ' -f 2-)
                    echo "%{F#669acc} %{F#fff}$device_alias"

                else
                    printf ''
                fi
                printf '\n'
            else
                echo "󰂲"
            fi
        else
            echo "󰂲 N/A"
        fi
    done
}

bluetooth_toggle() {
    if bluetoothctl show | grep -q "Powered: no"; then
        bluetoothctl power on >> /dev/null
        sleep 1

        devices_paired=$(bluetoothctl devices Paired | grep Device | cut -d ' ' -f 2)
        echo "$devices_paired" | while read -r line; do
            bluetoothctl connect "$line" >> /dev/null
        done
    else
        devices_paired=$(bluetoothctl devices Paired | grep Device | cut -d ' ' -f 2)
        echo "$devices_paired" | while read -r line; do
            bluetoothctl disconnect "$line" >> /dev/null
        done

        bluetoothctl power off >> /dev/null
    fi
}

case "$1" in
    --toggle)
        bluetooth_toggle
        ;;
    *)
        bluetooth_print
        ;;
esac
