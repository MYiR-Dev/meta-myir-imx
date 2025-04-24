DESCRIPTION = "myir tool and wifi firmware"
LICENSE = "LGPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=309cc7bace8769cfabdd34577f654f8e"

SRC_URI += " \
		file://etc/myir_test/ \
		file://etc/myir-hostapd.conf \
		file://etc/myir-udhcpd.conf \
 		file://usr/bin/ \
		file://10-static-eth0.network \
		file://11-static-eth1.network \
		file://20-static-usb0.network \
		file://LICENSE \
"
S="${WORKDIR}"

inherit  systemd

do_install() {
	install -d ${D}${systemd_system_unitdir}
	install -d ${D}${bindir}
	install -d ${D}/etc/myir_test/
	install -d ${D}/etc/
	install -d ${D}/${sysconfdir}/systemd/network/

	install -m 755 ${S}/10-static-eth0.network  ${D}/${sysconfdir}/systemd/network/
	install -m 755 ${S}/11-static-eth1.network  ${D}/${sysconfdir}/systemd/network/
	install -m 755 ${S}/20-static-usb0.network  ${D}/${sysconfdir}/systemd/network/
        install -m 755 ${S}/etc/myir_test/* ${D}/etc/myir_test/ 
        install -m 755 ${S}/etc/myir-hostapd.conf ${D}/etc/myir-hostapd.conf 
        install -m 755 ${S}/etc/myir-udhcpd.conf ${D}/etc/myir-udhcpd.conf
	install -m 755 ${S}${bindir}/* ${D}/${bindir}/

}

FILES:${PN} =" ${bindir}   \
	      /etc/myir_test/ \
	      /etc/ \
		/usr/lib \
	     ${sysconfdir}/systemd/network/ \
"
FILES_${PN}-dbg += "${libdir}/.debug"
INSANE_SKIP_${PN} = "ldflags"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "1"
INSANE_SKIP_${PN} = "${ERROR_QA} ${WARN_QA}"
INSANE_SKIP:${PN} = "file-rdeps"

