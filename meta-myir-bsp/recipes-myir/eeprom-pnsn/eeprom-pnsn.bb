SUMMARY = "Temp Ctrl"
DESCRIPTION = "Temperature Control"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

SRC_URI = " \
     file://eeprom-pnsn.service \
     file://libmyir_code.so \
     file://MEasyListen-DEV \
     "

S = "${UNPACKDIR}"

inherit systemd

do_install() {
        install -d -m 755 ${D}${systemd_system_unitdir}
	install -d ${D}/usr/bin
        install -d ${D}/usr/lib

        install -m 644 ${S}/eeprom-pnsn.service ${D}${systemd_system_unitdir}/eeprom-pnsn.service
	install -m 755 ${S}/MEasyListen-DEV ${D}/usr/bin
        install -m 755 ${S}/libmyir_code.so ${D}/usr/lib
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "eeprom-pnsn.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES_SOLIBSDEV = ""
FILES:${PN} = " \
                /usr/lib/libmyir_code.so \
                /usr/bin/MEasyListen-DEV \
                ${systemd_system_unitdir}/eeprom-pnsn.service \
"

INSANE_SKIP:${PN} += "already-stripped dev-elf"
