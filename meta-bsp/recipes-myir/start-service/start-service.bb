# MYIR - 2020   Alex .
DESCRIPTION = "Extra files for MYiR"
LICENSE = "LGPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=309cc7bace8769cfabdd34577f654f8e"

SRC_URI += "file://myir_start_service.sh \
           file://startservice.service \
           file://LICENSE"

S = "${WORKDIR}"

inherit systemd 

SYSTEMD_SERVICE_${PN} = "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'startservice.service', '', d)}"

do_install_append() {
	
	install -d ${D}${systemd_unitdir}/system
	install -d ${D}${sysconfdir}

	install -m 0644 ${WORKDIR}/startservice.service ${D}${systemd_system_unitdir}
	install -m 755 ${WORKDIR}/myir_start_service.sh ${D}${sysconfdir}
}

pkg_postinst_ontarget_${PN} () {
	if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
		if [ -n "$D" ]; then
			OPTS="--root=$D"
		fi
		systemctl $OPTS enable startservice.service
	fi
}

FILES_${PN}=" ${sysconfdir}   \
              ${sysconfdir}/system \
	  "
#For dev packages only
#INSANE_SKIP_${PN}-dev = "ldflags"
#INSANE_SKIP_${PN} = "${ERROR_QA} ${WARN_QA}"


