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
    fac-burn-emmc-full \
    ${@bb.utils.contains('MACHINENAME', 'mys-8mmx', 'tf-upgrade', '', d)} \
"



export IMAGE_BASENAME = "myir-image-burn"
