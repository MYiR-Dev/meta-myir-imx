# Copyright (C) 2015 Freescale Semiconductor
# Copyright 2017-2019 NXP
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
    package-management \
    splash \
    nfs-server \
    tools-debug \
    ssh-server-dropbear \
    hwcodecs \
    ${@bb.utils.contains('DISTRO_FEATURES', 'wayland', '', \
       bb.utils.contains('DISTRO_FEATURES',     'x11', 'x11-base x11-sato', \
                                                       '', d), d)} \
"
ERPC_COMPS ?= ""
ERPC_COMPS_append_mx7ulp = "packagegroup-imx-erpc"

ISP_PKGS = ""
ISP_PKGS_mx8mp = "packagegroup-imx-isp"

CORE_IMAGE_EXTRA_INSTALL += " \
    imx-uuc \
    packagegroup-core-full-cmdline \
    packagegroup-tools-bluetooth \
    packagegroup-fsl-tools-audio \
    packagegroup-fsl-tools-gpu \
    packagegroup-fsl-tools-gpu-external \
    packagegroup-fsl-tools-testapps \
    packagegroup-fsl-tools-benchmark \
    packagegroup-imx-security \
    packagegroup-fsl-gstreamer1.0 \
    packagegroup-fsl-gstreamer1.0-full \
    ${ERPC_COMPS} \
    ${ISP_PKGS} \
    autorun-script \
    myir-regulatory \
    tslib \
    tslib-calibrate \
    tslib-conf \
    tslib-uinput \
    tslib-tests \
    lftp \
    inetutils-ftp \
    ntp \
    tcpdump \
    proftpd \
    openvpn \
    bridge-utils \
    ffmpeg \
    x264 \
    pv \
    libgpiod \
    ppp-quectel \
    quectel-cm \
    qtsvg \
    qtquickcontrols \
    qtquickcontrols2 \
    qtmultimedia \
    qtvirtualkeyboard \
    fonts \
    tf-upgrade \
    sqlite3\
    nxp-demo-experience \
	v4l-utils \
	qmllive \
	firmware-imx \
	qt-demo \
	wifi-bt-conf \
	${@bb.utils.contains('MACHINENAME', 'myd-jx8mp', 'genext2fs', '', d)} \
"
