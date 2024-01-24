require recipes-graphics/drm/libdrm_2.4.99.imx.bb

LIC_FILES_CHKSUM = "file://xf86drm.c;beginline=9;endline=32;md5=c8a3b961af7667c530816761e949dc71"
IMX_LIBDRM_BRANCH = "libdrm-imx-2.4.102"
SRCREV = "40ea53973b99b7df07f472318918a8c2b310e4a7"

SRC_URI_remove = "file://musl-ioctl.patch"

IMX_LIBDRM_SRC_remove = "git://source.codeaurora.org/external/imx/libdrm-imx.git;protocol=https;nobranch=1"
IMX_LIBDRM_SRC_prepend = "git://github.com/nxp-imx/libdrm-imx.git;protocol=https;nobranch=1"
