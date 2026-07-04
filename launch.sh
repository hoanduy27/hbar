#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

if type "xrandr" > /dev/null 2>&1; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do

    # Get the monitor's geometry (handles both with and without "primary")
    geometry=$(xrandr --query | grep "^$m connected" | grep -oE '[0-9]+x[0-9]+\+[0-9]+\+[0-9]+' | head -1)
    
    if [ -z "$geometry" ]; then
        echo "Skipping $m - no geometry found"
        continue
    fi
    
    echo "Monitor: $m, Geometry: $geometry"
    
    # Extract resolution (before the + signs)
    resolution=$(echo "$geometry" | cut -d'+' -f1)
    
    # Extract width and height
    width=$(echo "$resolution" | cut -d'x' -f1)
    height=$(echo "$resolution" | cut -d'x' -f2)

    echo "Resolution: ${width}x${height}"
    
    if [ "$height" -gt "$width" ]; then
        echo "Launching vertical bar on $m"
        MONITOR=$m polybar -c ~/.config/polybar/config_vertical hdbar-left 2>&1 | tee -a /tmp/polybar-vert-left.log & disown
        MONITOR=$m polybar -c ~/.config/polybar/config_vertical hdbar-center 2>&1 | tee -a /tmp/polybar-vert-center.log & disown
        # MONITOR=$m polybar -c ~/.config/polybar/config_vertical hdbar-right 2>&1 | tee -a /tmp/polybar-vert-right.log & disown
    else
        echo "Launching landscape bar on $m"
        MONITOR=$m polybar hdbar-left 2>&1 | tee -a /tmp/polybar-left.log & disown
        MONITOR=$m polybar hdbar-center 2>&1 | tee -a /tmp/polybar-center.log & disown
        MONITOR=$m polybar hdbar-right 2>&1 | tee -a /tmp/polybar-right.log & disown
    fi
  done
else
    # Launch Polybar, using default config location ~/.config/polybar/config.ini
    polybar hdbar 2>&1 | tee -a /tmp/polybar.log & disown
fi

echo "Polybar launched..."