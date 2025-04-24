SUMMARY = "Temp Ctrl"
DESCRIPTION = "Temperature Control"
LICENSE = "GPL-2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"
PR = "1"

S = "${WORKDIR}"

SRC_URI = " \
     file://licenses/GPL-2 \
     file://eeprom-pnsn.service \
     file://MEasyListen-DEV \
     file://libmyir_code.so \
     "
inherit systemd

do_install() {
        install -d -m 755 ${D}${systemd_system_unitdir}
        install -d -m 755 ${D}/usr/bin/
        install -d -m 755 ${D}${libdir}

        install -m 755 ${WORKDIR}/eeprom-pnsn.service ${D}${systemd_system_unitdir}/eeprom-pnsn.service
        install -m 755 ${WORKDIR}/MEasyListen-DEV ${D}/usr/bin/

	cp ${WORKDIR}/libmyir_code.so ${WORKDIR}/libmyir_code.so.${PR}
        install -m 755 ${WORKDIR}/libmyir_code.so ${D}/usr/lib/
        install -m 755 ${WORKDIR}/libmyir_code.so.${PR} ${D}/usr/lib/
        cd ${D}/usr/lib/
        ln -sf libmyir_code.so.${PR} libmyir_code.so
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "eeprom-pnsn.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} += "/"
FILES:${PN} += "${libdir}/libmyir_code.so.*"
