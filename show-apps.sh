#!/bin/bash

current_ws=$(xdotool get_desktop)

# Collect windows in current workspace
list=""
for wid in $(wmctrl -lx | awk -v ws="$current_ws" '$2 == ws {print $1}'); do
    # Window title
    title=$(xprop -id "$wid" WM_NAME | cut -d'"' -f2 2>/dev/null)
    # WM_CLASS (app identifier, often like "firefox" or "gnome-terminal")
    class=$(xprop -id "$wid" WM_CLASS | cut -d'"' -f2 2>/dev/null)
    # Clean empty values
    [ -z "$title" ] && title="(no title)"
    [ -z "$class" ] && class="unknown"

    list+="$wid\t${class}: ${title}\n"
done

if [ -z "$list" ]; then
    rofi -e "No applications in this workspace"
    exit 0
fi

# Store current focused window
current_focus=$(xdotool getwindowfocus)

# Use rofi to choose with custom keybinding
choice=$(echo -e "$list" | cut -f2 | rofi -dmenu -i -p "Running Apps" -theme ~/.config/polybar/show-apps.rasi \
    -kb-custom-1 "Alt-Tab" \
    -select-row 0 \
    | while IFS= read -r line; do
        # Get window ID for current selection
        win_id=$(echo -e "$list" | grep "$line" | cut -f1)
        # Raise and focus the window
        xdotool windowactivate "$win_id"
        echo "$line"
    done
)

# Restore original focus if no selection was made
if [ -z "$choice" ]; then
    xdotool windowactivate "$current_focus"
else
    # Focus chosen window permanently
    win_id=$(echo -e "$list" | grep "$choice" | cut -f1)
    wmctrl -i -a "$win_id"
fi
