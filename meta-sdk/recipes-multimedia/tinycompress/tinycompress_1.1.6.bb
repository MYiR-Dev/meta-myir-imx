SUMMARY = "tinycompress library for compress audio offload in alsa"
DESCRIPTION = "A library to handle compressed formats like MP3 etc"
LICENSE = "BSD-3-Clause"

inherit autotools pkgconfig
LIC_FILES_CHKSUM = "file://COPYING;md5=cf9105c1a2d4405cbe04bbe3367373a0"

SRC_URI = "git://git.alsa-project.org/tinycompress.git;protocol=git;branch=master \
           file://0001-tinycompress-Add-id3-decoding.patch \
"
SRCREV = "995f2ed91045dad8c20485ab1a64727d22cd92e5"

S = "${WORKDIR}/git"
