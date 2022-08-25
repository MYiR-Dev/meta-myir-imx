# Copyright 2020 NXP

DESCRIPTION = "Kernel loadable module for RTL8188FU"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"

SRCBRANCH = "L5.10.9"
#RTL_KERNEL_SRC ?= "git:///media/liao/Linux_5.10.9/wifi-driver/rtl8188fu_linux_5.10.9;protocol=file"
RTL_KERNEL_SRC ?= "git://github.com/whistmazel/rtl8188fu.git;protocol=https"

SRC_URI = " \
    ${RTL_KERNEL_SRC};branch=${SRCBRANCH} \
"
SRCREV = "96cc0f052ac45d8b52ffc60c6314a3ab19ae3fd4"

S = "${WORKDIR}/git"

inherit module
