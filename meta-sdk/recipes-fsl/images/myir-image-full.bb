# Copyright (C) 2015 Freescale Semiconductor
# Copyright 2017-2019 NXP
# Released under the MIT license (see COPYING.MIT for the terms)

require recipes-fsl/images/imx-image-multimedia.bb

CONFLICT_DISTRO_FEATURES = "directfb"

ML_PKGS ?= ""
ML_PKGS_mx8 = "packagegroup-imx-ml"
ML_PKGS_mx8dxl = ""
ML_PKGS_mx8phantomdxl = ""

OPENCV_PKGS ?= ""
OPENCV_PKGS_append_imxgpu = " \
    opencv-apps \
    opencv-samples \
    python3-opencv \
"
IMAGE_INSTALL += " \
    ${OPENCV_PKGS} \
    ${ML_PKGS} \
    python3 \
    qtquickcontrols \
    qtquickcontrols2 \
    qtmultimedia \
    qtvirtualkeyboard \
    qt-demo \
    ppp-quectel \
    staticip-network \
    start-service \
    myir-rc-local \
    u-boot-fw-utils \
    libgpiod \
    can-utils \
    memtester \
    sqlite3 \
    tslib \
    tslib-calibrate \
    tslib-conf \
    tslib-tests \
    evtest \
    myir-linux-examples \
    quectel-cm \
"

IMAGE_INSTALL_append = "ffmpeg alsa-utils v4l-utils"
