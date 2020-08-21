require recipes-bsp/u-boot/u-boot-fw-utils_2019.07.bb

SRC_URI = "git://github.com/MYiR-Dev/myir-imx-uboot.git;branch=develop;protocol=https"
SRCREV = "b8604312e60b3d96fd340f9c8fe047dcf5c736a4"

MYS_IOT_PATH="file://0001-FEAT-mys-iot-fw_env-configure.patch"
SRC_URI += " \
	${@bb.utils.contains('MACHINENAME', 'mys-iot', '${MYS_IOT_PATH}', '', d)} \
"
inherit fsl-u-boot-localversion

LOCALVERSION ?= "-${SRCBRANCH}"
