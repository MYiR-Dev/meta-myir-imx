#!/bin/sh

# Send QUIT command to psplash to make it exit and clear the screen
# psplash uses Type=notify, so the daemon keeps running in background after systemd releases it
QUIT_SENT=0
for i in 1 2 3 4 5; do
    if [ -e /run/psplash_fifo ]; then
        echo "QUIT" > /run/psplash_fifo 2>/dev/null
        QUIT_SENT=1
        break
    fi
    usleep 100000
done

if [ "$QUIT_SENT" -eq 1 ]; then
    # Wait for psplash to clear screen and exit
    sleep 1
else
    # psplash already exited but left a residual progress bar, clear framebuffer directly
    dd if=/dev/zero of=/dev/fb0 bs=1536000 count=1 2>/dev/null
fi

# Unbind framebuffer console to prevent kernel messages from overwriting LVGL UI
echo 0 > /sys/class/vtconsole/vtcon1/bind 2>/dev/null

# Launch LVGL application
/usr/bin/myir_lvgl &
echo "auto run"

