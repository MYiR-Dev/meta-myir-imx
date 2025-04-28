DESCRIPTION = "i.MX U-Boot suppporting i.MX reference boards."

LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://Licenses/gpl-2.0.txt;md5=b234ee4d69f5fce4486a80fdaf4a4263"

UBOOT_SRC ?= "git://bgithub.xyz/LokVahKoor/myir-imx-uboot.git;protocol=https"
#UBOOT_SRC ?= "git:///media/home/didier/91/BSP/myir-i.mx9x-uboot;protocol=file"
SRC_URI = "${UBOOT_SRC};branch=${SRCBRANCH}"
#SRCBRANCH = "lf_v2024.04"
SRCBRANCH = "develop_2024.04"
LOCALVERSION ?= "-${SRCBRANCH}"
SRCREV = "ba6c3853b9aa24bb1b33fdd873a88c1825a67f6f"

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
