#!/bin/bash

# Toggle/cycle through Chrome browser windows (not PWAs)
# - If not on Chrome: focus the most recently used Chrome window
# - If on Chrome: cycle to the next Chrome window

# Get all Chrome window IDs (not PWAs)
CHROME_WINS=($(wmctrl -lx | grep "google-chrome.Google-chrome" | awk '{print $1}'))
NUM_WINS=${#CHROME_WINS[@]}

if [ $NUM_WINS -eq 0 ]; then
    # No Chrome windows, launch Chrome
    google-chrome &
    exit 0
fi

# Get currently active window
ACTIVE_WIN=$(xdotool getactivewindow 2>/dev/null)
ACTIVE_HEX=$(printf "0x%08x" "$ACTIVE_WIN" 2>/dev/null)

# Check if active window is a Chrome window and find its index
CURRENT_INDEX=-1
for i in "${!CHROME_WINS[@]}"; do
    if [ "$ACTIVE_HEX" = "${CHROME_WINS[$i]}" ]; then
        CURRENT_INDEX=$i
        break
    fi
done

if [ $CURRENT_INDEX -ge 0 ]; then
    # Currently on a Chrome window - cycle to next
    NEXT_INDEX=$(( (CURRENT_INDEX + 1) % NUM_WINS ))
    wmctrl -i -a "${CHROME_WINS[$NEXT_INDEX]}"
else
    # Not on Chrome - focus the most recently used Chrome window
    STACK=$(xprop -root _NET_CLIENT_LIST_STACKING 2>/dev/null | grep -oE '0x[0-9a-f]+')
    
    for win_id in $(echo "$STACK" | tac); do
        win_norm=$(printf "0x%08x" "$((win_id))" 2>/dev/null)
        for chrome_id in "${CHROME_WINS[@]}"; do
            if [ "$win_norm" = "$chrome_id" ]; then
                wmctrl -i -a "$chrome_id"
                exit 0
            fi
        done
    done
    
    # Fallback: focus first Chrome window
    wmctrl -i -a "${CHROME_WINS[0]}"
fi
