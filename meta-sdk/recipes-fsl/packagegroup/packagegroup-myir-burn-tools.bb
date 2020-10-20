# Copyright 2018-2019 NXP
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "Packagegroup to provide necessary tools for basic core image"

PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

RDEPENDS_${PN} = " \
    dosfstools \
    e2fsprogs-mke2fs \
    fsl-rc-local \
    fbset \
    ethtool \
    mtd-utils \
    mtd-utils-ubifs \
    procps \
    ptpd \
    linuxptp \
    cpufrequtils \
    nano \
    ntpdate \
    coreutils \
    mmc-utils \
    util-linux \
    e2fsprogs-resize2fs \
    autorun-script \
"
