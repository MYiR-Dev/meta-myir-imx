#!/bin/sh
export XDG_RUNTIME_DIR=/run/user/0
export QT_QPA_PLATFORM=wayland
rfkill unblock all
echo 0 > /sys/class/rfkill/rfkill1/state
sleep 2
echo 1 > /sys/class/rfkill/rfkill1/state
sleep 5
/home/root/mxapp2
