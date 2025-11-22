#!/bin/bash

setup_monitors() {
	# Auto-detect connected monitors
	MONITORS=$(xrandr --query | grep " connected" | grep -v eDP | cut -d" " -f1)
	MONITOR_COUNT=$(echo "$MONITORS" | wc -l)
	
	# Collect all windows before reconfiguration
	all_windows=($(bspc query -N -n .window))

    declare -A window_info
	
	echo "Detected monitors: $MONITORS"
	echo "Monitor count: $MONITOR_COUNT"
	
	for  win in "${all_windows[@]}"; do
	    desktop=$(bspc query -D -n "$win" --names)
	    window_info[$win]=$desktop
	done
	
	if [ "$MONITOR_COUNT" -eq 2 ]; then 
	    ~/.config/bspwm/display2.sh
	# Setup xrandr for extended displays (not mirrored)
	elif [ "$MONITOR_COUNT" -gt 1 ]; then
	    echo "Setting up $MONITOR_COUNT monitors for extended display..."
	    
	    # Get first monitor as primary
	    PRIMARY=$(echo "$MONITORS" | sed -n 1p)
	    xrandr --output "$PRIMARY" --auto --primary
	    
	    # Extend additional monitors to the right
	    POSITION="$PRIMARY"
	    for monitor in $(echo "$MONITORS" | tail -n +2); do
	        xrandr --output "$monitor" --auto --left-of "$POSITION"
	        POSITION="$monitor"
	    done
	   
	    # Wait for xrandr to apply
	    sleep 1
	fi

	# Now configure bspwm desktops
	# Re-query monitors after xrandr setup using bspc
	# MONITORS=$(bspc query -M --names)
	# ACTUAL_COUNT=$(echo "$MONITORS" | wc -l)

	

	if [ "$MONITOR_COUNT" -eq 1 ]; then
	    # Single monitor: assign all desktops
	    SINGLE_MON=$(echo "$MONITORS" | head -n 1)
	    bspc monitor "$SINGLE_MON" -d I II III IV V VI VII VIII IX X
	    echo "Single monitor setup: $SINGLE_MON with all desktops"
	    
	elif [ "$MONITOR_COUNT" -eq 2 ]; then
	    # Two monitors: split desktops 5-5
	    MON1=$(echo "$MONITORS" | sed -n 1p)
	    MON2=$(echo "$MONITORS" | sed -n 2p)
	    
	    bspc monitor "$MON1" -d I II III IV V
	    bspc monitor "$MON2" -d VI VII VIII IX X
	    
	    echo "Two monitor setup:"
	    echo "  $MON1: I II III IV V"
	    echo "  $MON2: VI VII VIII IX X"
	    
	elif [ "$MONITOR_COUNT" -eq 3 ]; then
	    # Three monitors: distribute desktops
	    MON1=$(echo "$MONITORS" | sed -n 1p)
	    MON2=$(echo "$MONITORS" | sed -n 2p)
	    MON3=$(echo "$MONITORS" | sed -n 3p)
	    
	    bspc monitor "$MON1" -d I II III IV
	    bspc monitor "$MON2" -d V VI VII VIII
	    bspc monitor "$MON3" -d IX X
	    
	    echo "Three monitor setup:"
	    echo "  $MON1: I II III IV"
	    echo "  $MON2: V VI VII VIII"
	    echo "  $MON3: IX X"
	    
	else
	    # Four or more monitors: distribute evenly
	    DESKTOP_PER_MONITOR=3
	    DESKTOP_LIST="I II III IV V VI VII VIII IX X"
	    DESK_COUNT=1
	    
	    for monitor in $MONITORS; do
	        START=$((($DESK_COUNT - 1) * $DESKTOP_PER_MONITOR + 1))
	        END=$(($DESK_COUNT * $DESKTOP_PER_MONITOR))
	        
	        DESKS=$(echo "$DESKTOP_LIST" | cut -d" " -f$START-$END)
	        bspc monitor "$monitor" -d $DESKS
	        
	        echo "  $monitor: $DESKS"
	        DESK_COUNT=$(($DESK_COUNT + 1))
	    done
	fi


        # Remove temporary desktops
	for monitor in "${monitors[@]}"; do
	   bspc desktop "$monitor:_temp_" -r 2>/dev/null
	done
    
        # Migrate windows back to their original desktops (or desktop 1 if doesn't exist)
        for win in "${all_windows[@]}"; do
            if bspc query -N -n "$win" &>/dev/null; then
                original_desktop="${window_info[$win]}"
            
            # Try to move to original desktop, fallback to first desktop if it doesn't exist
                if bspc query -D -d "$original_desktop" &>/dev/null; then
                    bspc node "$win" -d "$original_desktop"
                else
                    # Desktop doesn't exist anymore, move to first available
                    first_desktop=$(bspc query -D -m "${monitors[0]}" | head -n1)
                    bspc node "$win" -d "$first_desktop"
                fi
             fi
         done
}

setup_monitors

if command -v polybar &> /dev/null; then
    ~/.config/polybar/launch.sh
fi
