# Copyright (C) 2015 Freescale Semiconductor
# Copyright 2017-2021 NXP
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "NXP Image to validate i.MX machines. \
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
    debug-tweaks \
    tools-profile \
    tools-sdk \
    package-management \
    splash \
    nfs-server \
    tools-debug \
    ssh-server-dropbear \
    tools-testapps \
    hwcodecs \
    ${@bb.utils.contains('DISTRO_FEATURES', 'wayland', 'weston', \
       bb.utils.contains('DISTRO_FEATURES',     'x11', 'x11-base x11-sato', \
                                                       '', d), d)} \
"
ERPC_COMPS ?= ""
ERPC_COMPS_append_mx7ulp = "packagegroup-imx-erpc"

V2X_PKGS = ""
V2X_PKGS_mx8dxl = "packagegroup-imx-v2x"

DOCKER ?= ""
DOCKER_mx8 = "docker"

G2D_SAMPLES                 = ""
G2D_SAMPLES_imxgpu2d        = "imx-g2d-samples"
G2D_SAMPLES_imxgpu2d_imxdpu = ""

CORE_IMAGE_EXTRA_INSTALL += " \
    packagegroup-core-full-cmdline \
    packagegroup-tools-bluetooth \
    packagegroup-fsl-tools-audio \
    packagegroup-fsl-tools-gpu \
    packagegroup-fsl-tools-gpu-external \
    packagegroup-fsl-tools-testapps \
    packagegroup-fsl-tools-benchmark \
    packagegroup-imx-isp \
    packagegroup-imx-security \
    packagegroup-fsl-gstreamer1.0 \
    packagegroup-fsl-gstreamer1.0-full \
    wifi-bt-conf \
    wireless-tools \
    pv \
    devmem2 \
    openvpn \
    inetutils-ftp \
    haveged \
    tslib \
    tslib-calibrate \
    tslib-conf \
    tslib-uinput \
    tslib-tests \
    sqlite3 \
    v4l-utils \
    tcpdump \
    ppp-quectel \
    quectel-cm \
    proftpd    \
    libubootenv \
    myir-tool   \
    qtmultimedia \
    qtvirtualkeyboard  \
    qtquickcontrols \
    qtquickcontrols2  \
    qtsvg   \
    x264     \
    ${@bb.utils.contains('MACHINENAME', 'myd-jx8mma7', 'pcie-app', '', d)} \
    ${@bb.utils.contains('MACHINENAME', 'myd-jx8mma7', 'kernel-module-pcie', '', d)} \
    ${@bb.utils.contains('MACHINENAME', 'myd-jx8mma7', 'hmi', '', d)} \
    firmwared \
    ${@bb.utils.contains('DISTRO_FEATURES', 'x11 wayland', 'weston-xwayland xterm', '', d)} \
    ${V2X_PKGS} \
    ${DOCKER} \
    ${G2D_SAMPLES} \
"
