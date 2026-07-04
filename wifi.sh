#!/usr/bin/env bash

# WiFi Network Selector for Polybar
# Requires: nmcli, rofi, notify-send

# Get the WiFi interface name
INTERFACE=$(nmcli -t -f DEVICE,TYPE device | grep wifi | cut -d: -f1 | head -n1)

if [ -z "$INTERFACE" ]; then
    rofi -e "No WiFi interface found"
    exit 1
fi

# Get current connection
CURRENT_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)

# Scan for networks
nmcli device wifi rescan 2>/dev/null
sleep 1

# Get list of available networks with signal strength
WIFI_LIST=$(nmcli -f SSID,SIGNAL,SECURITY device wifi list | tail -n +2)

if [ -z "$WIFI_LIST" ]; then
    rofi -e "No networks found"
    exit 0
fi

# Format the network list for rofi
list=""
row_num=0
selected_row=0
while IFS= read -r line; do
    # Parse line more carefully
    SIGNAL=$(echo "$line" | awk '{print $(NF-1)}')
    SECURITY=$(echo "$line" | awk '{print $NF}')
    # SSID is everything except last two fields
    SSID=$(echo "$line" | awk '{NF-=2; print}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Skip empty SSIDs
    [ -z "$SSID" ] && continue
    
    # Determine signal icon
    if [[ "$SIGNAL" =~ ^[0-9]+$ ]]; then
        if [ "$SIGNAL" -ge 75 ]; then
            ICON="󰤨"
        elif [ "$SIGNAL" -ge 50 ]; then
            ICON="󰤥"
        elif [ "$SIGNAL" -ge 25 ]; then
            ICON="󰤢"
        else
            ICON="󰤟"
        fi
    else
        ICON="󰤥"
    fi
    
    # Determine security icon
    if [ "$SECURITY" = "--" ]; then
        SEC_ICON="🔓"
    else
        SEC_ICON="🔒"
    fi
    
    # Mark current connection and track row number
    if [ "$SSID" = "$CURRENT_SSID" ]; then
        DISPLAY_TEXT="✓ ${ICON} ${SSID} (${SIGNAL}%) ${SEC_ICON}"
        selected_row=$row_num
    else
        DISPLAY_TEXT="  ${ICON} ${SSID} (${SIGNAL}%) ${SEC_ICON}"
    fi
    
    # Add to list with metadata (SSID, signal, security, display)
    list+="${SSID}\t${SIGNAL}\t${SECURITY}\t${DISPLAY_TEXT}\n"
    ((row_num++))
done <<< "$WIFI_LIST"

# Add special options
list+="---\t\t\t---\n"
list+="__DISCONNECT__\t\t\t  󰤮 Disconnect\n"
list+="__REFRESH__\t\t\t  🔄 Refresh\n"

# Show rofi menu with selected row highlighted
choice=$(echo -e "$list" | cut -f4 | rofi -dmenu -i -p "WiFi Networks" \
    -theme ~/.config/polybar/show-apps.rasi \
    -theme-str 'window {width: 450px;}' \
    -selected-row "$selected_row")

# Exit if no selection
[ -z "$choice" ] && exit 0

# Handle special options
if echo "$choice" | grep -q "Disconnect"; then
    nmcli device disconnect "$INTERFACE"
    notify-send "WiFi" "Disconnected from $CURRENT_SSID"
    exit 0
fi

if echo "$choice" | grep -q "Refresh"; then
    exec "$0"
fi

if echo "$choice" | grep -q "^---"; then
    exit 0
fi

# Extract SSID from selection
SELECTED_SSID=$(echo -e "$list" | grep -F "$choice" | cut -f1)

# Check if already connected
if [ "$SELECTED_SSID" = "$CURRENT_SSID" ]; then
    notify-send "WiFi" "Already connected to $SELECTED_SSID"
    exit 0
fi

# Check if this is a saved/known connection
SAVED_CONNECTION=$(nmcli -t -f NAME connection show | grep -F "$SELECTED_SSID")

if [ -n "$SAVED_CONNECTION" ]; then
    # Connect to saved network (no password needed)
    if nmcli connection up "$SAVED_CONNECTION" 2>/dev/null; then
        notify-send "WiFi" "Connected to $SELECTED_SSID"
    else
        PASSWORD=$(rofi -dmenu -password -p "Password for $SELECTED_SSID" \
            -theme ~/.config/polybar/show-apps.rasi \
            -theme-str "window {width: 400px;} entry {placeholder: \"Password for [$SELECTED_SSID]\";}")
        
        if [ -n "$PASSWORD" ]; then
            if nmcli device wifi connect "$SELECTED_SSID" password "$PASSWORD" 2>/dev/null; then
                notify-send "WiFi" "Connected to $SELECTED_SSID"
            else
                notify-send "WiFi Error" "Failed to connect. Check password."
            fi
        fi
        
    fi
    exit 0
fi

# Not a saved connection - check if it needs a password
SECURITY=$(echo -e "$list" | grep -F "$choice" | cut -f3)

if [ "$SECURITY" = "--" ]; then
    # Open network, no password needed
    if nmcli device wifi connect "$SELECTED_SSID" 2>/dev/null; then
        notify-send "WiFi" "Connected to $SELECTED_SSID"
    else
        notify-send "WiFi Error" "Failed to connect to $SELECTED_SSID"
    fi
else
    # New secured network, ask for password
    PASSWORD=$(rofi -dmenu -password -p "Password for $SELECTED_SSID" \
        -theme ~/.config/polybar/show-apps.rasi \
        -theme-str "window {width: 400px;} entry {placeholder: \"Password for [$SELECTED_SSID]\";}")
    
    if [ -n "$PASSWORD" ]; then
        if nmcli device wifi connect "$SELECTED_SSID" password "$PASSWORD" 2>/dev/null; then
            notify-send "WiFi" "Connected to $SELECTED_SSID"
        else
            notify-send "WiFi Error" "Failed to connect. Check password."
        fi
    fi
fi