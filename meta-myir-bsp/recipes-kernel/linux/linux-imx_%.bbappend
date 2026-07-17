DELTA_KERNEL_DEFCONFIG:mx6ull-generic-bsp = "${UNPACKDIR}/rng-optimize.cfg"

FILESEXTRAPATHS:prepend:mx6ull-generic-bsp := "${THISDIR}/${PN}:"
SRC_URI:append:mx6ull-generic-bsp = " file://rng-optimize.cfg"
SRC_URI:append:mx6ull-generic-bsp = " file://key-optimize.cfg"
