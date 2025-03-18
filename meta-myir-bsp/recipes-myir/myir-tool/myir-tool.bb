DESCRIPTION = "myir tool and wifi firmware"
LICENSE = "LGPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=309cc7bace8769cfabdd34577f654f8e"

SRC_URI += " \
		file://etc/myir_test/ \
		file://etc/myir-hostapd.conf \
		file://etc/myir-udhcpd.conf \
		file://bcmd  \
		file://usr/lib/locale/zh_CN  \
		file://lib/firmware/brcm  \
 		file://usr/bin/ \
		file://10-static-end1.network \
		file://11-static-end2.network \
		file://bt.service \
		file://LICENSE \
"
S="${WORKDIR}"

inherit  systemd

do_install() {
	install -d ${D}${systemd_system_unitdir}
	install -d ${D}${bindir}
	install -d ${D}${nonarch_base_libdir}/firmware/bcmd/
	install -d ${D}${nonarch_base_libdir}/firmware/brcm/
	install -d ${D}/etc/myir_test/
	install -d ${D}/etc/
	install -d ${D}/usr/lib/locale/
	install -d ${D}/${sysconfdir}/systemd/network/

	install -m 755 ${S}/10-static-end1.network  ${D}/${sysconfdir}/systemd/network/
	install -m 755 ${S}/11-static-end2.network  ${D}/${sysconfdir}/systemd/network/
        install -m 755 ${S}/etc/myir_test/* ${D}/etc/myir_test/ 
        install -m 755 ${S}/etc/myir-hostapd.conf ${D}/etc/myir-hostapd.conf 
        install -m 755 ${S}/etc/myir-udhcpd.conf ${D}/etc/myir-udhcpd.conf
	install -m 755 ${S}${bindir}/* ${D}/${bindir}/
        install -m 0644 ${S}/bcmd/* ${D}${nonarch_base_libdir}/firmware/bcmd/ 
        install -m 0644 ${S}/lib/firmware/brcm/* ${D}${nonarch_base_libdir}/firmware/brcm/ 
	cp -r ${S}/usr/lib/locale/zh_CN ${D}/usr/lib/locale/

	install -m 644 ${WORKDIR}/bt.service ${D}${systemd_system_unitdir}/bt.service
}

FILES:${PN} =" ${bindir}   \
              ${nonarch_base_libdir}/firmware/bcmd/  \
	      /etc/myir_test/ \
	      /etc/ \
	      /usr/lib \
	     ${sysconfdir}/systemd/network/ \
	     /usr/lib/locale/zh_CN/* \
"
FILES_${PN}-dbg += "${libdir}/.debug"
INSANE_SKIP_${PN} = "ldflags"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "1"
INSANE_SKIP_${PN} = "${ERROR_QA} ${WARN_QA}"
INSANE_SKIP:${PN} = "file-rdeps"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "bt.service"
SYSTEMD_AUTO_ENABLE = "enable"
