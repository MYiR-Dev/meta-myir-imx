SUMMARY = "myir baord info"
DESCRIPTION = "sometimes driver will request firmware and wait for a 60s or 120s, We feed the firmware to it"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=a3ac5472be79591e880a452856ca24d1"


inherit  systemd

S = "${WORKDIR}"

SRC_URI = "file://hwrevision;subdir=${BP} \
           file://licenses/GPL-2;subdir=${BP} \
           file://myir-swupdate.service;subdir=${BP} \
           file://myir-swupdate.sh;subdir=${BP} \
           file://board_part_info.conf;subdir=${BP} \
           file://sw-versions;subdir=${BP} \
          "
S = "${WORKDIR}/${BP}"          

HW_MAJOR ?="1"
HW_MINOR ?="0"

#EMMC_DEV ?="2"
#EMMC_DEV_mx8mm = "2"

#SD_DEV ?= "1"
#SD_DEV_mx8mm = "1"

#ROOTFS_A_PART ?="2"
#ROOTFS_B_PART ?="3"
					

do_install(){
	install -d ${D}${systemd_system_unitdir}
	install -d ${D}${sysconfdir}

	install -m 644 ${S}/myir-swupdate.service ${D}${systemd_system_unitdir}/myir-swupdate.service
	install -m 755 ${S}/myir-swupdate.sh ${D}${sysconfdir}/myir-swupdate.sh
	install -m 644 ${S}/sw-versions ${D}${sysconfdir}/sw-versions
	install -m 644 ${S}/hwrevision ${D}${sysconfdir}/hwrevision
	echo "${MACHINE} ${HW_MAJOR}.${HW_MINOR}" >  ${D}${sysconfdir}/hwrevision
	
	install -m 644 ${S}/board_part_info.conf ${D}${sysconfdir}/board_part_info.conf
	
}


SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "myir-swupdate.service"
SYSTEMD_AUTO_ENABLE = "enable"
