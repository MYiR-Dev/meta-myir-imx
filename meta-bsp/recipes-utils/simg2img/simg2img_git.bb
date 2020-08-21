# Copyright (C) 2015 Freescale Semiconductor
# Copyright 2017 NXP
# Released under the MIT license (see COPYING.MIT for the terms)
DESCRIPTION = "A tool to convert Android sparse images to raw images"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://COPYING;md5=b433a746dd6fe8862028b1d7fc412a4d"

DEPENDS = "zlib"

SIMG2IMG_SRC ?= "git://source.codeaurora.org/external/imx/simg2img.git;protocol=https"
SRC_BRANCH = "master"

SRC_URI = "${SIMG2IMG_SRC};branch=${SRC_BRANCH}"
SRCREV = "ae70b83c606f5ac912af28343296d1da4a5ba3ea"
S = "${WORKDIR}/git"

EXTRA_OEMAKE += 'CC="${CC}"'

do_install() {
    install -d ${D}${bindir}
    cp ${S}/simg2img ${D}${bindir}/
    chmod a+x ${D}${bindir}/simg2img
}

INSANE_SKIP_${PN} = "ldflags"
