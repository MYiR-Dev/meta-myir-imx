DELTA_KERNEL_DEFCONFIG:mx6ull-generic-bsp = "${UNPACKDIR}/rng-optimize.cfg"

FILESEXTRAPATHS:prepend:mx6ull-generic-bsp := "${THISDIR}/${PN}:"
SRC_URI:append:mx6ull-generic-bsp = " file://rng-optimize.cfg"
SRC_URI:append:mx6ull-generic-bsp = " file://key-optimize.cfg"
# MYD-JS8MPQ HDMI: expose a 1080p fallback only when EDID is unavailable.
FILESEXTRAPATHS:prepend:myd-js8mpq := "${THISDIR}/${PN}:"
SRC_URI:append:myd-js8mpq = " \
    file://0011-drm-imx8mp-hdmi-fallback-1080p-without-edid.patch \
    file://0012-drm-imx8mp-hdmi-prefer-valid-4k30.patch \
"
