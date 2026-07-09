#!/bin/bash
# Toggle a rofi popup to control the currently playing MPRIS media.

BACKEND="$HOME/.config/polybar/media-popup-backend.sh"
RASI="$HOME/.config/polybar/media-popup.rasi"

if pgrep -f "rofi -show media -modes" > /dev/null; then
    pkill -f "rofi -show media -modes"
    exit 0
fi

rofi -show media -modes "media:$BACKEND" -theme "$RASI" &
rofi_pid=$!

# The backend has no way to push updates on its own (rofi only re-runs
# the script on user action), so send its "tick" keybinding (Alt+1) on
# a timer to make the progress bar advance in near real time. The loop
# exits on its own once rofi does.
(
    win=""
    for _ in $(seq 1 20); do
        win=$(xdotool search --pid "$rofi_pid" --limit 1 2> /dev/null)
        [ -n "$win" ] && break
        sleep 0.1
    done
    [ -z "$win" ] && exit 0

    # xdotool's --window flag sends a synthetic (XSendEvent) key, which
    # rofi ignores; activating the window once and sending a real key
    # event (XTest) to whatever is focused is what actually reaches it.
    # windowactivate can lose a race with rofi's own startup (it isn't
    # instantly focusable), so confirm focus actually landed before
    # ticking — otherwise alt+1 silently goes to whatever else has
    # focus and rofi never refreshes.
    for _ in $(seq 1 20); do
        xdotool windowactivate "$win" 2> /dev/null
        sleep 0.05
        [ "$(xdotool getactivewindow 2> /dev/null)" = "$win" ] && break
    done

    while kill -0 "$rofi_pid" 2> /dev/null; do
        if [ "$(xdotool getactivewindow 2> /dev/null)" != "$win" ]; then
            xdotool windowactivate "$win" 2> /dev/null
        fi
        xdotool key alt+1 2> /dev/null
        sleep 0.2
    done
) &

wait "$rofi_pid"
