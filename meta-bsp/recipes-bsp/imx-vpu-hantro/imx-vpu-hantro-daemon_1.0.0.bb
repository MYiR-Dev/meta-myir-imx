# Copyright 2021 NXP
DESCRIPTION = "i.MX HANTRO V4L2 Daemon"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://COPYING;md5=3c3fe2b904fd694f28d2f646ee16dddb"

inherit fsl-eula-unpack


SRC_URI = "${FSL_MIRROR}/${BP}.bin;fsl-eula=true"

SRC_URI[md5sum] = "d44dab8d03e9e2506d9a2b917bcc5110"
SRC_URI[sha256sum] = "e88f5ef19d9a2d8dc6e6460025ca8e36adb838838453043c4aee2755375c92c6"

DEPENDS += "imx-vpu-hantro"
DEPENDS_append_mx8mp = " imx-vpu-hantro-vc"

PLATFORM_mx8mm = "IMX8MM"
PLATFORM_mx8mq = "IMX8MQ"
PLATFORM_mx8mp = "IMX8MP"

EXTRA_OEMAKE += " \
                  CROSS_COMPILE="${HOST_PREFIX}" \
                  SDKTARGETSYSROOT="${STAGING_DIR_TARGET}" \
                  CTRLSW_HDRPATH="${STAGING_DIR_TARGET}"/usr/include \
"
do_compile () {
    oe_runmake PLATFORM="${PLATFORM}" all
}

do_install () {
    oe_runmake DEST_DIR="${D}" PLATFORM="${PLATFORM}" install
}

FILES_${PN} += "/usr/bin"

INSANE_SKIP_${PN} = "ldflags"

PACKAGE_ARCH = "${MACHINE_SOCARCH}"
COMPATIBLE_MACHINE = "(mx8mq|mx8mm|mx8mp)"
