# MYIR - 2020   Alex .
DESCRIPTION = "MYD-LMX1 Expand part"
LICENSE = "LGPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=309cc7bace8769cfabdd34577f654f8e"

SRC_URI += "file://expand-part.service\
           file://expand_part.sh \
           file://LICENSE"

S = "${WORKDIR}"

inherit systemd 

SYSTEMD_SERVICE:${PN} = "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'expand-part.service', '', d)}"

do_install:append() {
	
	install -d ${D}${systemd_unitdir}/system
	install -d ${D}${sysconfdir}

	install -m 0644 ${WORKDIR}/expand-part.service ${D}${systemd_system_unitdir}
	install -m 755 ${WORKDIR}/expand_part.sh ${D}${sysconfdir}/expand_part.sh
}

pkg_postinst_ontarget_${PN} () {
	if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
		if [ -n "$D" ]; then
			OPTS="--root=$D"
		fi
		systemctl $OPTS enable expand-part.service
	fi
}

FILES:${PN}=" ${sysconfdir}   \
              ${sysconfdir}/system \
	  "
#For dev packages only
#INSANE_SKIP_${PN}-dev = "ldflags"
#INSANE_SKIP_${PN} = "${ERROR_QA} ${WARN_QA}"


