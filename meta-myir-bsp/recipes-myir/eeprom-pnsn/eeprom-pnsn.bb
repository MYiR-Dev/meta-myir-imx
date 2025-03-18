SUMMARY = "Temp Ctrl"
DESCRIPTION = "Temperature Control"
LICENSE = "GPL-2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"

S = "${WORKDIR}"

SRC_URI = " \
     file://licenses/GPL-2 \
     file://eeprom-pnsn.service \
     "
inherit systemd

do_install() {
        install -d -m 755 ${D}${systemd_system_unitdir}

        install -m 644 ${WORKDIR}/eeprom-pnsn.service ${D}${systemd_system_unitdir}/eeprom-pnsn.service
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "eeprom-pnsn.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} += "/"
