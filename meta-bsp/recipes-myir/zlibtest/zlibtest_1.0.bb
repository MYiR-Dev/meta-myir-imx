# zlibtest_1.0.bb 
SUMMARY = "Simple zlibtest application"
DESCRIPTION = "A minimal program that use zlib package"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://compression.c \
	file://compression.h \
	file://Makefile \
	file://zlibtest.c"

S = "${WORKDIR}"

DEPENDS = "zlib"
do_compile() {
	oe_runmake
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 zlibtest ${D}${bindir}
}

FILES:${PN} = "${bindir}/zlibtest"

