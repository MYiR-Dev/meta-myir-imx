SUMMARY = "auto run scripts"
DESCRIPTION = "sometimes we need scripts auto run with system boot up"

LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://${THISDIR}/files/licenses/GPL-2;md5=893e842b220e4ff976ebe9a212f5e51d"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    file://autorun.service;subdir=${BP} \
    file://autorun_y6ull.service;subdir=${BP} \
    file://autorun.sh;subdir=${BP} \
    file://autorun_y6ull.sh;subdir=${BP} \
    file://licenses/GPL-2;subdir=${BP} \
"

PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit systemd

do_install:myd-js8mpq() {
    install -d ${D}${systemd_system_unitdir}
    install -d ${D}${bindir}

    install -m 0644 ${S}/autorun.service ${D}${systemd_system_unitdir}/
    install -m 0755 ${S}/autorun.sh ${D}${bindir}/
}

do_install:mx6ull-nxp-bsp() {
    install -d ${D}${systemd_system_unitdir}
 		install -d ${D}${bindir}
   
    install -m 0644 ${S}/autorun_y6ull.service ${D}${systemd_system_unitdir}/autorun.service
    install -m 0755 ${S}/autorun_y6ull.sh ${D}${bindir}/autorun.sh
}

do_install:mx9-nxp-bsp() {
    install -d ${D}${systemd_system_unitdir}
                install -d ${D}${bindir}

    install -m 0644 ${S}/autorun.service ${D}${systemd_system_unitdir}/
    install -m 0755 ${S}/autorun.sh ${D}${bindir}/
}

FILES:${PN} += " \
    ${systemd_system_unitdir}/autorun.service \
"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "autorun.service"
SYSTEMD_AUTO_ENABLE = "enable"
