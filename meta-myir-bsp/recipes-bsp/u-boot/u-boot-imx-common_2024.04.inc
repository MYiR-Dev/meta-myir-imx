DESCRIPTION = "i.MX U-Boot suppporting i.MX reference boards."

LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://Licenses/gpl-2.0.txt;md5=b234ee4d69f5fce4486a80fdaf4a4263"

#UBOOT_SRC ?= "git://github.com/nxp-imx/uboot-imx.git;protocol=https"
UBOOT_SRC ?= "git:///media/home/didier/91/BSP/myir-i.mx9x-uboot;protocol=file"
SRC_URI = "${UBOOT_SRC};branch=${SRCBRANCH}"
#SRCBRANCH = "lf_v2024.04"
SRCBRANCH = "develop_2024.04"
LOCALVERSION ?= "-${SRCBRANCH}"
#SRCREV = "de16f4f17221b2ff72b8cb18c28cd8a29f3c2710"
SRCREV = "1357b1546b290ce0633c40d5a45a5e9e05c0919a"
#SRCREV = "d365b543824ac965f9ebb209b1e34cd6841f427b"
#fac
#SRCREV = "e212b2972975eb7bc5111bcc2cada71f2c17fa0d"
#SRCREV = "0c36e24433839ea119b0aa0103b2174bd7d4a6c5"

DEPENDS += " \
    bc-native \
    bison-native \
    dtc-native \
    flex-native \
    gnutls-native \
    xxd-native \
"

S = "${WORKDIR}/git"
B = "${WORKDIR}/build"

inherit fsl-u-boot-localversion

BOOT_TOOLS = "imx-boot-tools"
