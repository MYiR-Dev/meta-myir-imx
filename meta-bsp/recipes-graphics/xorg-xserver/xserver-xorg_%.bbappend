FILESEXTRAPATHS_prepend := "${THISDIR}/${BPN}:"

# Trailing space is intentional due to a bug in meta-freescale
SRC_URI += "file://0001-glamor-Use-CFLAGS-for-EGL-and-GBM.patch "
