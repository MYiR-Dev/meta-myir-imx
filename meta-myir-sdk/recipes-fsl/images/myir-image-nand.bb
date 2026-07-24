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
    ssh-server-openssh \
    allow-empty-password \
    allow-root-login \
    empty-root-password \
    post-install-logging \
"

IMAGE_INSTALL += " \
    firmwared \
    curl \
    bc \
    evtest \
    coreutils \
    net-tools \
    memtester \
    util-linux \
    ethtool \
    file \
    v4l-utils \
    iperf3 \
    can-utils \
    i2c-tools \
    udev-extraconf \
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

CLINFO              ?= ""
CLINFO:imxgpu        = "clinfo"
CLINFO:mx8mm-nxp-bsp = ""
CLINFO:mx7-nxp-bsp   = ""

DOCKER            ?= ""
DOCKER:mx8-nxp-bsp = "docker"
DOCKER:mx9-nxp-bsp = "docker"
