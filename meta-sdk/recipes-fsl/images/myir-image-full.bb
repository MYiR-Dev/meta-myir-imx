# Copyright (C) 2015 Freescale Semiconductor
# Copyright 2017-2021 NXP
# Released under the MIT license (see COPYING.MIT for the terms)

require recipes-fsl/images/imx-image-multimedia.bb

inherit populate_sdk_qt6

CONFLICT_DISTRO_FEATURES = "directfb"

DEFAULT_IMAGE_LINGUAS:libc-glibc += "zh-cn"

IMAGE_INSTALL += " \
    curl \
    packagegroup-imx-ml \
    packagegroup-qt6-imx \
    tzdata \
    ${IMAGE_INSTALL_OPENCV} \
    ${IMAGE_INSTALL_PARSEC}"

IMAGE_INSTALL_OPENCV              = ""
IMAGE_INSTALL_OPENCV:imxgpu       = "${IMAGE_INSTALL_OPENCV_PKGS}"
IMAGE_INSTALL_OPENCV:mx93-nxp-bsp = "${IMAGE_INSTALL_OPENCV_PKGS}"
IMAGE_INSTALL_OPENCV_PKGS = " \
    opencv-apps \
    opencv-samples \
    python3-opencv"

IMAGE_INSTALL_PARSEC = " \
    packagegroup-security-tpm2 \
    packagegroup-security-parsec \
    swtpm \
    softhsm \
    os-release \
    auto-wifi  \
    htpdate  \
    hmi  \
    ppp-quectel  \
    start-service  \
    vim  \
    quectel-cm  \
    ppp  \
    qtbase  \
    qtmultimedia \
    qtvirtualkeyboard \
    wireless-tools \
    pv \
    devmem2 \
    v4l-utils \
    tslib \
    tslib-calibrate \
    tslib-conf \
    tslib-uinput \
    tslib-tests \
    tcpdump \
    openvpn \
    proftpd \
    cinematicexperience-rhi  \
    u-boot-imx-fw-utils \
    board-info \
    swupdate \
    swupdate-usb \
    swupdate-progress \
    log4cpp \
    devmem2 \
    sqlite3  \
    readline  \
    tftp-hpa  \
    myir-utils \
    myir-test-function \
    ${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'optee-client optee-os', '', d)}"
