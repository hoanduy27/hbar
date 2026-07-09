#!/bin/bash

stdbuf -oL /usr/bin/dbus-monitor --session "interface='org.freedesktop.Notifications',member='NotificationClosed'" 2>/dev/null |
while read -r line; do
    case "$line" in
        *member=NotificationClosed*)
            read -r id_line
            read -r reason_line
            id=$(echo "$id_line" | grep -oE '[0-9]+')
            reason=$(echo "$reason_line" | grep -oE '[0-9]+')

            # reason 2 = the user actively dismissed/clicked the popup.
            # reason 1 (timeout) is left in history, since the user never saw it.
            if [ "$reason" = "2" ] && [ -n "$id" ]; then
                dunstctl history-rm "$id"
            fi
            ;;
    esac
done
