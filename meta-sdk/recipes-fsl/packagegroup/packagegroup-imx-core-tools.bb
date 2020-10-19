# Copyright 2018-2019 NXP
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "Packagegroup to provide necessary tools for basic core image"

PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

RDEPENDS_${PN} = " \
    evtest \
    e2fsprogs-mke2fs \
    fsl-rc-local \
    fbset \
    i2c-tools \
    iproute2 \
    memtester \
    ethtool \
    mtd-utils \
    mtd-utils-ubifs \
    procps \
    iw \
    can-utils \
    ntpdate \
    mmc-utils \
    udev-extraconf \
    e2fsprogs-resize2fs \
"
