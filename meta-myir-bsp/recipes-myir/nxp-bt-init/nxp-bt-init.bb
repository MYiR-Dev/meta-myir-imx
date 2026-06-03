SUMMARY = "Bluetooth initialization"
DESCRIPTION = "Installs a systemd service to run nxp-bt-init.sh automatically at boot"

LICENSE = "CLOSED"
PV = "0.1"
PR = "r1"

DEPENDS += "systemd"
inherit systemd

SRC_URI = " \
		file://nxp-bt-init.service \
		file://nxp-bt-init.sh \
"

do_install (){
	install -d ${D}${bindir}
	install -m 0755 ${UNPACKDIR}/nxp-bt-init.sh ${D}${bindir}

	install -d ${D}${systemd_unitdir}/system
	install -m 0644 ${UNPACKDIR}/nxp-bt-init.service ${D}${systemd_unitdir}/system/nxp-bt-init.service
}

FILES:${PN} = "\
		${bindir}/nxp-bt-init.sh \
		${systemd_unitdir}/system/nxp-bt-init.service \
"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "nxp-bt-init.service"
SYSTEMD_AUTO_ENABLE = "enable"

