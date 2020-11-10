#!/bin/sh
export XDG_RUNTIME_DIR=/run/user/0
export QT_QPA_PLATFORM=wayland
memtester 1G 2000 &
python3 /home/root/main.py
