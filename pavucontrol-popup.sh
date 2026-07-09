#!/bin/sh
# Toggle pavucontrol, auto-closing it when it loses focus.

case "$1" in
    --popup)
        if pgrep -x pavucontrol >/dev/null; then
            pkill -x pavucontrol
            exit 0
        fi

        pavucontrol &
        pid=$!

        win=""
        for _ in $(seq 1 20); do
            win=$(xdotool search --pid "$pid" --limit 1 2>/dev/null)
            [ -n "$win" ] && break
            sleep 0.1
        done
        [ -z "$win" ] && exit 0

        xdotool windowactivate "$win" 2>/dev/null

        while kill -0 "$pid" 2>/dev/null; do
            active=$(xdotool getactivewindow 2>/dev/null)
            if [ "$active" != "$win" ]; then
                kill "$pid" 2>/dev/null
                break
            fi
            sleep 0.3
        done
        ;;
    *)
        echo ""
        ;;
esac
