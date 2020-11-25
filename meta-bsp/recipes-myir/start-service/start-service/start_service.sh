#!/bin/sh
echo "start service" > /var/startservice.log

export XDG_RUNTIME_DIR=/run/user/0
export QT_QPA_PLATFORM=wayland

exit 0
