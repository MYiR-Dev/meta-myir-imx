SUMMARY = "zlibtest compression example application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"


SRC_URI = "git://github.com/coin-haha/ziptest.git;protocol=https;branch=main \
           file://zlibtest.service"


SRCREV = "68ea659a9c3839f68a5bd46b68b68e9a7d5e026d"
PV = "1.0+git${SRCPV}"

DEPENDS = "zlib"
RDEPENDS:${PN} = "zlib"


inherit systemd

S = "${WORKDIR}/git"


SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "zlibtest.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_compile() {
    oe_runmake
}

do_install() {

    install -d ${D}${bindir}
    install -m 0755 zlibtest ${D}${bindir}

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/zlibtest.service ${D}${systemd_system_unitdir}
}

FILES:${PN} += "${systemd_system_unitdir}/zlibtest.service"
