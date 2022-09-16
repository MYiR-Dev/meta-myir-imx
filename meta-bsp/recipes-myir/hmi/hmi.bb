SUMMARY = "myir hmi 2.0"
DESCRIPTION = "myir hdmi 2.0 qt application"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"

S = "${WORKDIR}"

SRC_URI = "file://licenses/GPL-2 \
           file://home/root/hmi.sh \
		   file://home/root/mxapp2 \
		   file://usr/lib/fonts/msyh.ttc \
		   file://usr/share/myir/ecg.dat \
		   file://usr/share/myir/resp.text \
		   file://hmi.service \
          "
          
inherit  systemd

S = "${WORKDIR}"
ROOT_HOME="/home/root"


					

do_install (){
	install -d ${D}${systemd_system_unitdir}
	install -d ${D}${datadir}
	install -d ${D}${datadir}/myir
	install -d ${D}${datadir}/myir/Video
	install -d ${D}${datadir}/myir/Audio
	install -d ${D}${datadir}/myir/Capture
	install -d ${D}${nonarch_libdir}/fonts
	install -d ${D}${ROOT_HOME}

	
	install -m 755 ${WORKDIR}${ROOT_HOME}/hmi.sh ${D}${ROOT_HOME}/hmi.sh
	install -m 755 ${WORKDIR}${ROOT_HOME}/mxapp2 ${D}${ROOT_HOME}/mxapp2
	install -m 755 ${WORKDIR}${nonarch_libdir}/fonts/msyh.ttc ${D}${nonarch_libdir}/fonts/msyh.ttc
	install -m 755 ${WORKDIR}${datadir}/myir/ecg.dat ${D}${datadir}/myir/ecg.dat
	install -m 755 ${WORKDIR}${datadir}/myir/resp.text ${D}${datadir}/myir/resp.text

	install -m 644 ${WORKDIR}/hmi.service ${D}${systemd_system_unitdir}/hmi.service
	
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE_${PN} = "hmi.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES_${PN} = "/"
INSANE_SKIP_${PN} = "file-rdeps"
