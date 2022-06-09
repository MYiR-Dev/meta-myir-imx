# Copyright 2018-2019 NXP
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "This is the basic core image with minimal tests"

inherit core-image

IMAGE_FEATURES += " \
    debug-tweaks \
    tools-profile \
    package-management \
    splash \
    nfs-server \
    tools-debug \
    ssh-server-dropbear \
    hwcodecs \
"
SDKIMAGE_FEATURES_append = " \
    staticdev-pkgs \
"
IMAGE_INSTALL += " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'wayland', ' weston weston-examples weston-init','', d)} \
    imx-test \
    packagegroup-myir-burn-tools \
    packagegroup-imx-security \
	${@bb.utils.contains('MACHINENAME', 'myd-jx8mp', 'tf-upgrade', '', d)} \
	${@bb.utils.contains('MACHINENAME', 'myd-jx8mp', 'fac-burn-emmc-full', '', d)} \
    ${@bb.utils.contains('UBOOT_CONFIG', 'emmc', 'fac-burn-emmc-full', '', d)} \
	${@bb.utils.contains('UBOOT_CONFIG', 'nand', 'fac-burn-nand-full', '', d)} \
"



export IMAGE_BASENAME = "myir-image-burn"
