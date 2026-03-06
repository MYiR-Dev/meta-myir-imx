#!/bin/sh
export QT_WAYLAND_SHELL_INTEGRATION=xdg-shell
export QTWEBENGINE_DISABLE_SANDBOX=1
export QT_QPA_EGLFS_ALWAYS_SET_MODE=1
export WAYLAND_DISPLAY=/run/wayland-0
export XDG_RUNTIME_DIR=/run/user/0
export  QT_QPA_PLATFORM=linuxfb:fb=/dev/fb0:offset=0x0
echo on > /sys/devices/platform/bus@f0000/20000000.i2c/i2c-1/1-003c/power/control
timedatectl set-ntp yes
timedatectl set-local-rtc 1
systemctl restart systemd-timesyncd.service
/usr/sbin/mxapp2
