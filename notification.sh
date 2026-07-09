#!/bin/bash

notification_print() {
    if ! paused=$(dunstctl is-paused 2>/dev/null); then
        echo "󰂲 N/A"
        return
    fi

    if [ "$paused" = "true" ]; then
        echo "󰂛 muted"
        return
    fi

    unread=$(( $(dunstctl count waiting) + $(dunstctl count displayed) + $(dunstctl count history) ))

    if [ "$unread" -gt 0 ]; then
        echo "%{F#df4545}󰂞 $unread%{F-}"
    else
        echo "󰂜"
    fi
}

notification_history() {
    count=$(dunstctl count history)

    for _ in $(seq 1 "$count"); do
        dunstctl history-pop
    done
}

case "$1" in
    --toggle-pause)
        dunstctl set-paused toggle
        ;;
    --history)
        notification_history
        ;;
    --close-all)
        dunstctl close-all && dunstctl history-clear
        ;;
    *)
        notification_print
        ;;
esac
