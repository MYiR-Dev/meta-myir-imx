#!/bin/sh
psplash-drm -w --framerate 20 -n 50 --background ffffff --filename=/usr/share/psplash/splashscreen-animated_%05d.png
killall weston
export QT_WAYLAND_SHELL_INTEGRATION=xdg-shell
export QTWEBENGINE_DISABLE_SANDBOX=1
export QT_QPA_EGLFS_ALWAYS_SET_MODE=1
export WAYLAND_DISPLAY=/run/wayland-0
export XDG_RUNTIME_DIR=/run/user/0
export  QT_QPA_PLATFORM=linuxfb:fb=/dev/fb0:offset=0x0
echo on > /sys/devices/platform/bus@f0000/20000000.i2c/i2c-1/1-003c/power/control
#timedatectl set-ntp yes
#timedatectl set-local-rtc 1

# Part 1: Enhanced Time Synchronization Configuration
CONFIG_FILE="/etc/systemd/timesyncd.conf"
TARGET_VALUE="ntp.ntsc.ac.cn cn.ntp.org.cn time1.google.com time2.google.com time3.google.com time4.google.com"
TARGET_LINE="FallbackNTP=${TARGET_VALUE}"
TIME_MODIFIED=0

echo "[TimeSync] Checking time server configuration..."

# Check for exact match of target configuration
if grep -qxF "${TARGET_LINE}" "${CONFIG_FILE}"; then
    echo "[TimeSync] Exact configuration match found, no modification needed"
else
    echo "[TimeSync] Configuration update required, processing..."
    cp "${CONFIG_FILE}" "${CONFIG_FILE}.bak"
    
    # Remove all FallbackNTP related configurations (including comments)
    sed -i '/^#*FallbackNTP=.*/d' "${CONFIG_FILE}"
    
    # Ensure [Time] configuration section exists
    if ! grep -nR '\[Time\]' "${CONFIG_FILE}"; then
        echo "[Time] Configuration section missing, creating..."
        echo -e "\n[Time]" >> "${CONFIG_FILE}"
    fi
    
    # Insert new configuration under [Time] section
    if sed -i "/\[Time\]/a ${TARGET_LINE}" "${CONFIG_FILE}"; then
        echo "[TimeSync] New configuration successfully written"
        TIME_MODIFIED=1
    else
        echo "[TimeSync] Error: Configuration write failed" >&2
    fi
fi

if [ $TIME_MODIFIED -eq 1 ]; then
    systemctl restart systemd-timesyncd.service
    echo "[TimeSync] Time synchronization service restarted"
fi

CONFIG_FILE="/etc/systemd/system.conf"

# Verify config file existence
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file $CONFIG_FILE not found" >&2
fi

# Backup original file (optional)
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak" && echo "Backup created: ${CONFIG_FILE}.bak"

# Configuration check & add function
check_and_add() {
    local key="$1"
    if ! grep -q "^${key}$" "$CONFIG_FILE"; then
        echo "$key" >> "$CONFIG_FILE"
        echo "Added configuration: $key"
    else
        echo "Configuration already exists: $key"
    fi
}

# Process first configuration
check_and_add "RuntimeWatchdogSec=15"

# Process second configuration
check_and_add "RuntimeWatchdogPreSec=15"

# Part 2: Application Launch (remain unchanged)
echo "[Application] Starting mxapp2..."
/usr/sbin/mxapp2 &
echo "[Application] Program launched"

echo "All operations completed"
