#!/bin/sh
export XDG_RUNTIME_DIR=/run/user/0
export QT_QPA_PLATFORM=wayland
sleep 3

gst-launch-1.0 -v imxcompositor_g2d name=comp \
sink_0::xpos=0 sink_0::ypos=0 sink_0::width=640 sink_0::height=480 \
sink_1::xpos=0 sink_1::ypos=480 sink_1::width=640 sink_1::height=480 ! \
video/x-raw,format=RGB16 ! waylandsink window-height=960 window-width=640 \
v4l2src device=/dev/video0 ! video/x-raw,width=640,height=480 ! comp.sink_0 \
v4l2src device=/dev/video1 ! video/x-raw,width=640,height=480 ! comp.sink_1  &

sleep 8
/home/root/mes
