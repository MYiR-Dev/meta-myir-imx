# Copyright 2018-2026 MYIR
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "This is the basic core image with minimal tests. \
This image contains everything used to test i.MX machines including GUI, \
demos and lots of applications. This creates a very large image, not \
suitable for production."
LICENSE = "MIT"

inherit core-image

### WARNING: This image is NOT suitable for production use and is intended
###          to provide a way for users to reproduce the image used during
###          the validation process of i.MX BSP releases.

## Select Image Features
IMAGE_FEATURES += " \
    tools-profile \
    tools-sdk \
    package-management \
    splash \
    nfs-client \
    tools-debug \
    ssh-server-openssh \
    hwcodecs \
    allow-empty-password \
    allow-root-login \
    empty-root-password \
    post-install-logging \
    ${@bb.utils.contains('DISTRO_FEATURES', 'wayland', 'weston','', d)} \
"

SDKIMAGE_FEATURES:append = " \
    staticdev-pkgs \
"



CLINFO              ?= ""
CLINFO:imxgpu        = "clinfo"
CLINFO:mx8mm-nxp-bsp = ""
CLINFO:mx7-nxp-bsp   = ""

V2X_PKGS = ""
V2X_PKGS:mx8dxl-nxp-bsp = "packagegroup-imx-v2x"

DOCKER            ?= ""
DOCKER:mx8-nxp-bsp = "docker"
DOCKER:mx9-nxp-bsp = "docker"


SWUPDATE          ?= ""
SWUPDATE:mx9-nxp-bsp = "lua swupdate swupdate-www swupdate-progress swupdate-client swupdate-tools-ipc systemd-swusys json-c"

OPTEE_TEST          ?= ""
OPTEE_TEST:mx9-nxp-bsp = "lvm2 optee-test python3-cryptography optee-examples openssl"

G2D_SAMPLES              = ""
G2D_SAMPLES:imxgpu2d     = "imx-g2d-samples"
G2D_SAMPLES:mx93-nxp-bsp = "imx-g2d-samples"
G2D_SAMPLES:mx943-nxp-bsp = "imx-g2d-samples"

CORE_IMAGE_EXTRA_INSTALL += " \
    packagegroup-core-full-cmdline \
    packagegroup-tools-bluetooth \
    packagegroup-fsl-tools-audio \
    packagegroup-fsl-tools-gpu \
    packagegroup-fsl-tools-gpu-external \
    packagegroup-fsl-tools-testapps \
    packagegroup-fsl-tools-benchmark \
    packagegroup-imx-isp \
    packagegroup-imx-core-tools \
    packagegroup-imx-security \
    packagegroup-fsl-gstreamer1.0 \
    packagegroup-fsl-gstreamer1.0-full \
    firmwared \
    ${@bb.utils.contains('MACHINE_FEATURES', 'crrm', 'imx-secure-enclave-crrm', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'x11 wayland', 'weston-xwayland xterm', '', d)} \
    ${V2X_PKGS} \
    curl \
    ${CLINFO} \
    v4l-utils \
    tcpdump \
    u-boot-imx-env \
    libubootenv \
    libubootenv-bin \
    uboot-env \
    tzdata \
    tslib \
    tslib-calibrate \
    tslib-conf \
    tslib-uinput \
    tslib-tests \
    iperf3 \
    alsa-utils \
    serialcheck \
    libdrm-tests \
    sqlite3 \
    auto-wifi \
    hostapd \
    autorun-script \
    ppp \
    ppp-quectel \
    myir-test-function \
    ${SWUPDATE} \
    ${OPTEE_TEST} \
    myir-lvgl \
    myir-tools \
    board-info \
    vim \
    nxp-bt-init \
    pstore-conf \
    aw-xm729 \
    quectel-cm \
    libmodbus \
    myir-regulatory \
    ${@bb.utils.contains('MACHINE_FEATURES', 'hailo', 'hailo-pci hailo-firmware packagegroup-hailo-hailort', '', d)} \
"

export IMAGE_BASENAME = "myir-image-emmc"
