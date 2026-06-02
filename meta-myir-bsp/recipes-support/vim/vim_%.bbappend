# Disable GTK GUI: the wayland+x11 sysroot is missing gdk/gdkx.h
PACKAGECONFIG:remove = "gtkgui"
