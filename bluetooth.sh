#!/bin/bash

maxlen=20
state_file="/tmp/polybar-bt-index"
fifo="/tmp/polybar-bt-fifo"

get_controllers() {
    bluetoothctl list | grep Controller | cut -d ' ' -f 2
}

any_controller_powered() {
    local ctrl
    for ctrl in $(get_controllers); do
        bluetoothctl show "$ctrl" | grep -q "Powered: yes" && return 0
    done
    return 1
}

declare -A device_ctrl

# Populates the global $devices array and $device_ctrl map with the
# connected devices of every controller. `devices Connected` only reports
# for the currently selected controller. Each fresh `bluetoothctl` process
# needs a moment to sync its object cache over D-Bus, so `select` and
# `devices Connected` are run in a single session (via heredoc) per
# controller instead of separate invocations, which otherwise race and can
# return an empty list. The original default controller is restored after.
get_connected_devices() {
    devices=()
    device_ctrl=()

    local default_ctrl
    default_ctrl=$(bluetoothctl list | grep '\[default\]' | cut -d ' ' -f 2)

    local ctrl dev
    for ctrl in $(get_controllers); do
        while read -r dev; do
            [ -n "$dev" ] || continue
            devices+=("$dev")
            device_ctrl["$dev"]="$ctrl"
        done < <(bluetoothctl <<EOF | grep '^Device' | cut -d ' ' -f 2
select $ctrl
devices Connected
EOF
)
    done

    [ -n "$default_ctrl" ] && bluetoothctl select "$default_ctrl" >/dev/null 2>&1
}

format_device() {
    local device="$1"
    local device_info device_alias battery
    if [ -n "${device_ctrl[$device]}" ]; then
        device_info=$(bluetoothctl <<EOF
select ${device_ctrl[$device]}
info $device
EOF
)
    else
        device_info=$(bluetoothctl info "$device")
    fi
    device_alias=$(echo "$device_info" | grep "Alias" | cut -d ' ' -f 2-)
    [ ${#device_alias} -gt $maxlen ] && device_alias="${device_alias:0:$(( maxlen*2/3 ))}...${device_alias: -$(( maxlen/3 ))}"
    battery=$(echo "$device_info" | grep "Battery Percentage" | grep -oP '\(\K[0-9]+(?=\))')
    [ -n "$battery" ] && device_alias="$device_alias ($battery%)"
    echo "$device_alias"
}

current_index() {
    local count="$1"
    local index=0
    [ -f "$state_file" ] && index=$(cat "$state_file")
    [[ "$index" =~ ^[0-9]+$ ]] || index=0
    echo $(( index % count ))
}

print_current() {
    if [ "$(systemctl is-active "bluetooth.service")" != "active" ]; then
        echo "󰂲 N/A"
        return
    fi

    if ! any_controller_powered; then
        echo "󰂲"
        return
    fi

    get_connected_devices
    count=${#devices[@]}

    if [ "$count" -eq 0 ]; then
        echo "󰂯"
        return
    fi

    index=$(current_index "$count")
    label=$(format_device "${devices[$index]}")
    [ "$count" -gt 1 ] && label="$label ($(( index + 1 ))/$count)"

    # echo "󰂱 %{F#669acc} %{F#fff}$label "
    echo "󰂱 $label "
}

bluetooth_next() {
    get_connected_devices
    count=${#devices[@]}
    [ "$count" -eq 0 ] && return

    index=$(current_index "$count")
    echo $(( (index + 1) % count )) > "$state_file"

    [ -p "$fifo" ] && timeout 1 bash -c "echo next > '$fifo'" 2>/dev/null
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

bluetooth_watch() {
    [ -p "$fifo" ] || mkfifo "$fifo"

    bluetoothctl > "$fifo" 2>/dev/null &
    local bt_pid=$!
    trap 'kill "$bt_pid" 2>/dev/null' EXIT

    print_current
    while read -r _ <"$fifo"; do
        print_current
    done
}

case "$1" in
    --toggle)
        bluetooth_toggle
        ;;
    --next)
        bluetooth_next
        ;;
    *)
        bluetooth_watch
        ;;
esac
