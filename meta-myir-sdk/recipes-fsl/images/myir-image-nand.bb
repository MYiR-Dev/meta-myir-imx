# Copyright 2018-2026 MYIR
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "This is the basic core image with minimal tests"

inherit core-image

IMAGE_BASENAME = "myir-image-nand"

# Only machines explicitly supported by this image recipe (extend via bbappend if needed).
COMPATIBLE_MACHINE = "^(myd-y6ull-14x14-nand-256d|myd-y6ull-14x14-nand-512d)$"

# Common installation package
IMAGE_FEATURES += " \
    splash \
    nfs-client \
    tools-debug \
    ssh-server-openssh \
    hwcodecs \
    allow-empty-password \
    allow-root-login \
    empty-root-password \
    post-install-logging \
"

IMAGE_INSTALL += " \
    packagegroup-imx-core-tools \
    packagegroup-fsl-gstreamer1.0 \
    packagegroup-fsl-gstreamer1.0-full \
    firmwared \
    ${CLINFO} \
    curl \
    net-tools \
    v4l-utils \
    tcpdump \
    iperf3 \
    hostapd \
    sqlite3 \
    tzdata \
    alsa-utils \
    serialcheck \
    u-boot-imx-env \
    libubootenv \
    tslib \
    tslib-calibrate \
    tslib-conf \
    tslib-uinput \
    tslib-tests \
    bridge-utils \
    libmodbus \
    ppp \
    ppp-quectel \
    libdrm \
    imx-kobs \
    mtd-utils \
    mtd-utils-ubifs \
    myir-lvgl \
    myir-test-function \
    myir-tools \
    firmware-brcm43362 \
    autorun-script \
"

SDKIMAGE_FEATURES:remove = " \
    staticdev-pkgs \
"

#imx6ull 256N256D 512N512D
#256N256D
MYIR_Y6ULX_256N256D_IMAGE_FEATURES = " \
"

MYIR_Y6ULX_256N256D_IMAGE_INSTALL = " \
"

#512N512D
MYIR_Y6ULX_512N512D_IMAGE_FEATURES = " \
    tools-profile \
    tools-sdk \
    package-management \
"

MYIR_Y6ULX_512N512D_IMAGE_INSTALL = " \
    packagegroup-imx-security \
"

IMAGE_FEATURES:append:myd-y6ull-14x14-nand-256d = "${MYIR_Y6ULX_256N256D_IMAGE_FEATURES}"
IMAGE_INSTALL:append:myd-y6ull-14x14-nand-256d = "${MYIR_Y6ULX_256N256D_IMAGE_INSTALL}"

IMAGE_FEATURES:append:myd-y6ull-14x14-nand-512d = "${MYIR_Y6ULX_512N512D_IMAGE_FEATURES}"
IMAGE_INSTALL:append:myd-y6ull-14x14-nand-512d = "${MYIR_Y6ULX_512N512D_IMAGE_INSTALL}"



CLINFO              ?= ""
CLINFO:imxgpu        = "clinfo"
CLINFO:mx8mm-nxp-bsp = ""
CLINFO:mx7-nxp-bsp   = ""

DOCKER            ?= ""
DOCKER:mx8-nxp-bsp = "docker"
DOCKER:mx9-nxp-bsp = "docker"