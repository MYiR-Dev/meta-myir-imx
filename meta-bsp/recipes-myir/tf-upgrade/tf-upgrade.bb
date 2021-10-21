SUMMARY = "tf upgrade service"
DESCRIPTION = "when board boot up with EMMC,insert a tf card and then upgrade the system"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"


inherit  systemd

S = "${WORKDIR}"

SRC_URI = "file://check_upgrade.sh \
           file://check_upgrade.service \
           file://info.txt \
           file://licenses/GPL-2 \
          "


do_install(){
	install -d ${D}${systemd_system_unitdir}
	install -d ${D}${base_sbindir}
	install -d ${D}/upgrade/
	
	install -m 644 ${WORKDIR}/check_upgrade.service ${D}${systemd_system_unitdir}/check_upgrade.service
	install -m 755 ${WORKDIR}/check_upgrade.sh ${D}${base_sbindir}/check_upgrade.sh
	
	install -m 644 ${WORKDIR}/info.txt ${D}/upgrade/info.txt
	
}


SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE_${PN} = "check_upgrade.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES_${PN} = "/"
INSANE_SKIP_${PN} = "file-rdeps"