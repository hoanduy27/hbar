#!/bin/bash

bar="▁▂▃▄▅▆▇█"
dict="s/;//g;"
config_file="/tmp/polybar_cava_config"
current_sink=""
num_bars=20

# Function to get current default sink
get_default_sink() {
    pactl get-default-sink 2>/dev/null
}

# Function to get monitor source for a sink
get_monitor_source() {
    local sink=$1
    pactl list sinks short 2>/dev/null | grep "$sink" | awk '{print $2".monitor"}'
}

# Function to create cava config with specific source
create_cava_config() {
    local source=$1
    echo "
[general]
bars = $num_bars

[input]
method = pulse
source = $source

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7

[eq]
1=1
2=1
3=1
4=1
5=1

[smooth]
noise_reduction = 50
integral = 77

" > "$config_file"
}

# Create dictionary for character replacement
i=0
while [ $i -lt ${#bar} ]; do
    dict="${dict}s/$i/${bar:$i:1}/g;"
    i=$((i+1))
done
# dict=${dict:7}

# Function to start cava with current sink
start_cava() {
    local sink=$(get_default_sink)
    local monitor_source=$(get_monitor_source "$sink")
    
    # Fallback to auto if monitor source detection fails
    if [ -z "$monitor_source" ]; then
        monitor_source="auto"
    fi
    
    create_cava_config "$monitor_source"
    current_sink="$sink"
    
    # Kill any existing cava processes
    pkill -f "cava -p $config_file" 2>/dev/null >/dev/null
    
    # Start cava in background and capture its PID
    cava -p "$config_file" 2>/dev/null | while read -r line; do
        output=$(echo "$line" | sed "$dict")

        echo ${output: -$(( (num_bars + 1)/2 ))}
    done &
    
    cava_pid=$!
    echo "$cava_pid" > /tmp/cava_polybar_pid
}

# Function to check if sink changed
check_sink_change() {
    local new_sink=$(get_default_sink)
    if [ "$new_sink" != "$current_sink" ]; then
        return 0
    fi
    return 1
}

# Cleanup function
cleanup() {
    if [ -f /tmp/cava_polybar_pid ]; then
        kill "$(cat /tmp/cava_polybar_pid)" 2>/dev/null
        rm -f /tmp/cava_polybar_pid
    fi
    pkill -f "cava -p $config_file" 2>/dev/null
    rm -f "$config_file"
    exit 0
}

# Set up signal handlers
trap cleanup TERM INT EXIT

# Initial start
start_cava

# Monitor for sink changes every 2 seconds
while true; do
    sleep 2
    if check_sink_change; then
        start_cava
    fi
    
    # Check if cava process is still running
    if [ -f /tmp/cava_polybar_pid ]; then
        if ! kill -0 "$(cat /tmp/cava_polybar_pid)" 2>/dev/null; then
            start_cava
        fi
    else
        start_cava
    fi
done
