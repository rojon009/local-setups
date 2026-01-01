#!/bin/bash

# Toggle/cycle through Antigravity windows
# - If not on Antigravity: focus the most recently used Antigravity window
# - If on Antigravity: cycle to the next Antigravity window

APP_CLASS="antigravity.Antigravity"
LAUNCH_CMD="antigravity"

# Get all app window IDs
APP_WINS=($(wmctrl -lx | grep "$APP_CLASS" | awk '{print $1}'))
NUM_WINS=${#APP_WINS[@]}

if [ $NUM_WINS -eq 0 ]; then
    $LAUNCH_CMD &
    exit 0
fi

# Get currently active window
ACTIVE_WIN=$(xdotool getactivewindow 2>/dev/null)
ACTIVE_HEX=$(printf "0x%08x" "$ACTIVE_WIN" 2>/dev/null)

# Check if active window is this app and find its index
CURRENT_INDEX=-1
for i in "${!APP_WINS[@]}"; do
    if [ "$ACTIVE_HEX" = "${APP_WINS[$i]}" ]; then
        CURRENT_INDEX=$i
        break
    fi
done

if [ $CURRENT_INDEX -ge 0 ]; then
    # Currently on this app - cycle to next
    NEXT_INDEX=$(( (CURRENT_INDEX + 1) % NUM_WINS ))
    wmctrl -i -a "${APP_WINS[$NEXT_INDEX]}"
else
    # Not on this app - focus the most recently used window
    STACK=$(xprop -root _NET_CLIENT_LIST_STACKING 2>/dev/null | grep -oE '0x[0-9a-f]+')
    
    for win_id in $(echo "$STACK" | tac); do
        win_norm=$(printf "0x%08x" "$((win_id))" 2>/dev/null)
        for app_id in "${APP_WINS[@]}"; do
            if [ "$win_norm" = "$app_id" ]; then
                wmctrl -i -a "$app_id"
                exit 0
            fi
        done
    done
    
    # Fallback: focus first window
    wmctrl -i -a "${APP_WINS[0]}"
fi

