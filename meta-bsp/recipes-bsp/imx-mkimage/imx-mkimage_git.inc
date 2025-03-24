# Copyright 2017-2019 NXP
 
DEPENDS = "zlib-native openssl-native"

SRCBRANCH = "imx_5.4.3_2.0.0"
IMX_MKIMAGE_SRC ?= "git://github.com/nxp-imx/imx-mkimage.git;protocol=https"
SRC_URI = "${IMX_MKIMAGE_SRC};branch=${SRCBRANCH} \
					${@bb.utils.contains('MACHINENAME', 'myd-jx8mx', 'file://0001-FEAT-myd_jx8mx-imx8mq-2GDDR-configure.patch', '', d)}"
SRCREV = "0fcc82965c695f4754b87ae09b1ec79c0ce6c3b2"
S = "${WORKDIR}/git"

BOOT_TOOLS = "imx-boot-tools"
SYSROOT_DIRS += "/boot"
