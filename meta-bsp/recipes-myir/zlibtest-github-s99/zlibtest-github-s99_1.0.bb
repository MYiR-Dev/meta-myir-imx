SUMMARY = "zlibtest compression example application with direct rcS startup"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "git://github.com/coin-haha/ziptest.git;protocol=https;branch=main \
           file://S99zlibtest.sh"

SRCREV = "68ea659a9c3839f68a5bd46b68b68e9a7d5e026d"
PV = "1.0+git${SRCPV}"

DEPENDS = "zlib"
RDEPENDS:${PN} = "zlib"

S = "${WORKDIR}/git"

do_compile() {
    oe_runmake
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 zlibtest ${D}${bindir}

    install -d ${D}${sysconfdir}/rcS.d
    install -m 0755 ${WORKDIR}/S99zlibtest.sh ${D}${sysconfdir}/rcS.d/S99zlibtest
}

FILES:${PN} += "${sysconfdir}/rcS.d/S99zlibtest"