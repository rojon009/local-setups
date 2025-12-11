#!/bin/bash

# Setup keyboard shortcuts for toggle scripts
# Preserves existing shortcuts that aren't managed by this script

set -e

echo "=== Installing required packages ==="

# Check if running as root or use sudo
if [ "$EUID" -eq 0 ]; then
    APT_CMD="apt-get"
else
    APT_CMD="sudo apt-get"
fi

# Required packages:
# - wmctrl: window management (focus, list windows)
# - xdotool: get active window ID
# - x11-utils: provides xprop (window stacking order)
PACKAGES="wmctrl xdotool x11-utils"

# Check which packages need to be installed
MISSING_PACKAGES=""
for pkg in $PACKAGES; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        MISSING_PACKAGES="$MISSING_PACKAGES $pkg"
    fi
done

if [ -n "$MISSING_PACKAGES" ]; then
    echo "Installing:$MISSING_PACKAGES"
    $APT_CMD update -qq
    $APT_CMD install -y $MISSING_PACKAGES
    echo "✓ Packages installed"
else
    echo "✓ All required packages already installed"
fi

echo ""
echo "=== Setting up keyboard shortcuts ==="

SHORTCUTS_DIR="/home/rojon/shortcuts"
GSETTINGS="/usr/bin/gsettings"
SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
CUSTOM_SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
BASE_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

# Define shortcuts: name, command, binding
declare -a SHORTCUTS=(
    "Toggle Chrome|${SHORTCUTS_DIR}/toggle-chrome.sh|<Control><Alt><Shift>c"
    "Toggle Warp|${SHORTCUTS_DIR}/toggle-warp.sh|<Control><Alt><Shift>t"
    "Toggle Slack|${SHORTCUTS_DIR}/toggle-slack.sh|<Control><Alt><Shift>s"
    "Toggle DBeaver|${SHORTCUTS_DIR}/toggle-dbeaver.sh|<Control><Alt><Shift>d"
    "Toggle Cursor|${SHORTCUTS_DIR}/toggle-cursor.sh|<Control><Alt><Shift>r"
    "Toggle Firefox|${SHORTCUTS_DIR}/toggle-firefox.sh|<Control><Alt><Shift>f"
    "Toggle WhatsApp|${SHORTCUTS_DIR}/toggle-whatsapp.sh|<Control><Alt><Shift>w"
)

# Get existing custom keybindings
EXISTING=$($GSETTINGS get $SCHEMA custom-keybindings)

# Parse existing paths into array
declare -a EXISTING_PATHS=()
if [[ "$EXISTING" != "@as []" && "$EXISTING" != "[]" ]]; then
    # Remove brackets and quotes, split by comma
    CLEANED=$(echo "$EXISTING" | tr -d "[]'" | tr ',' '\n')
    while IFS= read -r path; do
        path=$(echo "$path" | xargs)  # trim whitespace
        if [[ -n "$path" ]]; then
            EXISTING_PATHS+=("$path")
        fi
    done <<< "$CLEANED"
fi

echo "Found ${#EXISTING_PATHS[@]} existing shortcut(s)"

# Function to check if a command already has a shortcut
find_existing_slot() {
    local target_command="$1"
    for path in "${EXISTING_PATHS[@]}"; do
        local cmd=$($GSETTINGS get "${CUSTOM_SCHEMA}:${path}" command 2>/dev/null | tr -d "'")
        if [[ "$cmd" == "$target_command" ]]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

# Find the next available slot number
find_next_slot() {
    local max=-1
    for path in "${EXISTING_PATHS[@]}"; do
        if [[ "$path" =~ custom([0-9]+) ]]; then
            local num="${BASH_REMATCH[1]}"
            if (( num > max )); then
                max=$num
            fi
        fi
    done
    echo $((max + 1))
}

# Track all paths (existing + new)
declare -a ALL_PATHS=("${EXISTING_PATHS[@]}")

# Configure each shortcut
for shortcut in "${SHORTCUTS[@]}"; do
    IFS='|' read -r name command binding <<< "$shortcut"
    
    # Check if this command already has a shortcut
    existing_path=$(find_existing_slot "$command")
    
    if [[ -n "$existing_path" ]]; then
        # Update existing shortcut
        GPATH="${CUSTOM_SCHEMA}:${existing_path}"
        echo "↻ Updating: ${name} -> ${binding}"
    else
        # Create new shortcut
        next_slot=$(find_next_slot)
        new_path="${BASE_PATH}/custom${next_slot}/"
        GPATH="${CUSTOM_SCHEMA}:${new_path}"
        ALL_PATHS+=("$new_path")
        EXISTING_PATHS+=("$new_path")  # Add to list so next iteration finds correct slot
        echo "✓ Adding: ${name} -> ${binding}"
    fi
    
    $GSETTINGS set "$GPATH" name "$name"
    $GSETTINGS set "$GPATH" command "$command"
    $GSETTINGS set "$GPATH" binding "$binding"
done

# Build the final keybindings path array
KEYBINDING_PATHS=""
for path in "${ALL_PATHS[@]}"; do
    KEYBINDING_PATHS="${KEYBINDING_PATHS}, '${path}'"
done
KEYBINDING_PATHS="[${KEYBINDING_PATHS:2}]"  # Remove leading ", "

# Update the list of custom keybindings
$GSETTINGS set $SCHEMA custom-keybindings "$KEYBINDING_PATHS"

echo ""
echo "All shortcuts configured! (Existing shortcuts preserved)"
echo ""
echo "Managed shortcuts:"
echo "  Ctrl+Alt+Shift+C = Chrome (cycle through windows)"
echo "  Ctrl+Alt+Shift+T = Warp Terminal (cycle through windows)"
echo "  Ctrl+Alt+Shift+S = Slack (cycle through windows)"
echo "  Ctrl+Alt+Shift+D = DBeaver (cycle through windows)"
echo "  Ctrl+Alt+Shift+R = Cursor (cycle through windows)"
echo "  Ctrl+Alt+Shift+F = Firefox (cycle through windows)"
echo "  Ctrl+Alt+Shift+W = WhatsApp (cycle through windows)"
echo ""
echo "Features:"
echo "  - Opens app if not running"
echo "  - Focuses most recently used window if app is open"
echo "  - Cycles through windows if already focused"
