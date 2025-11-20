#!/bin/bash

# Terminate already running bar instances
pgrep polybar >/dev/null && killall -q polybar
# If all your bars have ipc enabled, you can also use
# polybar-msg cmd quit

# while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar hdbar-left 2>&1 | tee -a /tmp/polybar-left.log & disown
    MONITOR=$m polybar hdbar-center 2>&1 | tee -a /tmp/polybar-center.log & disown
    MONITOR=$m polybar hdbar-right 2>&1 | tee -a /tmp/polybar-right.log & disown
  done
else
    # Launch Polybar, using default config location ~/.config/polybar/config.ini
    polybar hdbar 2>&1 | tee -a /tmp/polybar.log & disown
fi

echo "Polybar launched..."
