SUMMARY = "myir hmi 2.0"
DESCRIPTION = "myir hdmi 2.0 qt application"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"

S = "${WORKDIR}"

SRC_URI = "file://licenses/GPL-2 \
           file://home/root/mes-factory.sh \
					file://home/root/mes \
					file://home/root/boardinfo.json \
					file://home/root/1K1V.wav \
					file://usr/bin/pcba_test \
					file://usr/bin/eth0_eth1_net.sh \
					file://mes-factory.service \
          "
          
inherit  systemd

S = "${WORKDIR}"
ROOT_HOME="/home/root"


					

do_install (){
	install -d ${D}${systemd_system_unitdir}
	install -d ${D}${datadir}
	install -d ${D}${ROOT_HOME}
	install -d ${D}${bindir}

	
	install -m 755 ${WORKDIR}${ROOT_HOME}/mes-factory.sh ${D}${ROOT_HOME}/mes-factory.sh
	install -m 755 ${WORKDIR}${ROOT_HOME}/mes ${D}${ROOT_HOME}/mes
	install -m 755 ${WORKDIR}${ROOT_HOME}/boardinfo.json ${D}${ROOT_HOME}/boardinfo.json
	install -m 755 ${WORKDIR}${ROOT_HOME}/1K1V.wav ${D}${ROOT_HOME}/1K1V.wav
	install -m 755 ${WORKDIR}${bindir}/pcba_test ${D}${bindir}/pcba_test
	install -m 755 ${WORKDIR}${bindir}/eth0_eth1_net.sh ${D}${bindir}/eth0_eth1_net.sh
	install -m 644 ${WORKDIR}/mes-factory.service ${D}${systemd_system_unitdir}/mes-factory.service
	
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE_${PN} = "mes-factory.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES_${PN} = "/"
INSANE_SKIP_${PN} = "file-rdeps"
