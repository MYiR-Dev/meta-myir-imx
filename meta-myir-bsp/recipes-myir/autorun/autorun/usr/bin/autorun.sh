#!/bin/sh
source /etc/profile.d/weston_profile.sh
source /etc/profile.d/pulse_profile.sh

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

# Part 2: Touchscreen Calibration Configuration
RULES_FILE="/etc/udev/rules.d/touchscreen.rules"
RULE_LINE='SUBSYSTEM=="input", KERNEL=="event[0-9]*", ENV{ID_INPUT_TOUCHSCREEN}=="1", ENV{LIBINPUT_CALIBRATION_MATRIX}=" 61.509373 0.480948 0.019359 2.795640 116.671989 -0.044791"'

echo "[TouchScreen] Configuring touchscreen rules..."
if [ ! -f "$RULES_FILE" ]; then
    touch "$RULES_FILE"
    echo "[TouchScreen] Created new rules file"
fi

if ! grep -qF -- "$RULE_LINE" "$RULES_FILE"; then
    echo "$RULE_LINE" >> "$RULES_FILE"
    echo "[TouchScreen] Calibration matrix added"
else
    echo "[TouchScreen] Calibration rule already exists"
fi

# Apply device rules
sync
udevadm control --reload
udevadm trigger --action=change --subsystem-match=input
echo "[TouchScreen] Device rules reloaded"

# Part 3: Application Launch (remain unchanged)
echo "[Application] Starting mxapp2..."
/usr/sbin/mxapp2 &
echo "[Application] Program launched"

echo "All operations completed"
