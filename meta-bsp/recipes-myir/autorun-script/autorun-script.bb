SUMMARY = "auto run  scripts"
DESCRIPTION = "sometimes we need a scripts auto run with system boot up"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"


inherit  systemd

S = "${WORKDIR}"

SRC_URI = "file://autorun.service \
           file://licenses/GPL-2 \
          "
          



					

do_install(){
	install -d ${D}${systemd_system_unitdir}

	install -m 644 ${WORKDIR}/autorun.service ${D}${systemd_system_unitdir}/autorun.service
}


SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE_${PN} = "autorun.service"
SYSTEMD_AUTO_ENABLE = "enable"

