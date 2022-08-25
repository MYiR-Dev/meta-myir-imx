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
    ssh-server-dropbear \
"
ERPC_COMPS ?= ""
ERPC_COMPS_append_mx7ulp = "packagegroup-imx-erpc"

ISP_PKGS = ""
ISP_PKGS_mx8mp = "packagegroup-imx-isp"

CORE_IMAGE_EXTRA_INSTALL += " \
    imx-uuc \
    packagegroup-core-full-cmdline \
    packagegroup-fsl-tools-audio \
    packagegroup-fsl-gstreamer1.0 \
    packagegroup-fsl-gstreamer1.0-full \
    iperf3 \
    myir-regulatory \
    tslib \
    tslib-calibrate \
    tslib-conf \
    tslib-uinput \
    tslib-tests \
    bridge-utils \
    firmware-brcm43362 \
    tf-upgrade \
    v4l-utils \
    libjpeg-turbo \
    libgpiod \
    libgpiod-tools \
    hostapd \
    iptables \
    vsftpd \
    udev-extraconf \
    kernel-module-rtl8188fu \
    v4l-utils \
    libjpeg-turbo \
    libgpiod \
    iptables \
    i2c-tools \
    mtd-utils \
	firmware-imx \
	wifi-bt-conf \
"
IMAGE_INSTALL_append += "libgpiod"
