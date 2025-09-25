#!/bin/bash

# Terminate already running bar instances
pgrep polybar >/dev/null && killall -q polybar
# If all your bars have ipc enabled, you can also use
# polybar-msg cmd quit

# while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch Polybar, using default config location ~/.config/polybar/config.ini
polybar hdbar 2>&1 | tee -a /tmp/polybar.log & disown

echo "Polybar launched..."
