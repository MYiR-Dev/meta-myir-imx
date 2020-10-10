# Copyright 2018-2019 NXP
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "This is the basic core image with minimal tests"

inherit core-image

IMAGE_FEATURES += " \
    splash \
    nfs-server \
    ssh-server-dropbear \
    hwcodecs \
"
SDKIMAGE_FEATURES_append = " \
    staticdev-pkgs \
    packagegroup-imx-core-tools \
"
IMAGE_INSTALL += " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'wayland', ' weston weston-examples weston-init','', d)} \
    alsa-utils \
    ppp-quectel \
    staticip-network \
    start-service \
    u-boot-imx-fw-utils \
    myir-rc-local \
    libgpiod \
    sqlite3 \
    v4l-utils \
    evtest \
    myir-linux-examples \
    quectel-cm \
"
export IMAGE_BASENAME = "myir-image-core"
