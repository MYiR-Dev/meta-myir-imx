SUMMARY = "myir autorun 2.0"
DESCRIPTION = "myir hdmi 2.0 qt application"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"

S = "${WORKDIR}"

SRC_URI = "file://licenses/GPL-2 \
	   file://usr/sbin/ \
	   file://usr/bin/autorun.sh \
	   file://usr/share/fonts/ttf/msyh.ttc \
	   file://usr/share/myir/ecg.dat \
	   file://usr/share/myir/resp.text \
	   file://usr/share/myir/Video/ \
	   file://usr/share/myir/Music/ \
	   file://usr/share/myir/Capture/ \
	   file://autorun.service \
          "
          
inherit  systemd

S = "${WORKDIR}"

					

do_install (){
	install -d ${D}${systemd_system_unitdir}
	install -d ${D}${datadir}
	install -d ${D}${datadir}/myir
	install -d ${D}${datadir}/myir/Video
	install -d ${D}${datadir}/myir/Music
	install -d ${D}${datadir}/myir/Capture
	install -d ${D}/etc/init/
	install -d ${D}/usr/share/fonts/ttf/
        install -d ${D}${sbindir}
        install -d ${D}${bindir}
	#install -d ${D}${nonarch_libdir}/fonts

	
	install -m 755 ${WORKDIR}${bindir}/autorun.sh ${D}${bindir}/autorun.sh
	install -m 755 ${WORKDIR}${sbindir}/* ${D}${sbindir}/
	install -m 755 ${WORKDIR}/usr/share/fonts/ttf/msyh.ttc ${D}/usr/share/fonts/ttf/msyh.ttc
	install -m 755 ${WORKDIR}${datadir}/myir/ecg.dat ${D}${datadir}/myir/ecg.dat
	install -m 755 ${WORKDIR}${datadir}/myir/resp.text ${D}${datadir}/myir/resp.text
	install -m 755 ${WORKDIR}${datadir}/myir/Video/* ${D}${datadir}/myir/Video
	install -m 755 ${WORKDIR}${datadir}/myir/Music/* ${D}${datadir}/myir/Music
	install -m 755 ${WORKDIR}${datadir}/myir/Capture/* ${D}${datadir}/myir/Capture

	install -m 644 ${WORKDIR}/autorun.service ${D}${systemd_system_unitdir}/autorun.service
	
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "autorun.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} = "${systemd_system_unitdir} \
	      ${datadir}/myir \
	      ${datadir}/myir/Video \
              ${datadir}/myir/Audio \
              ${datadir}/myir/Capture \
	      /etc \
              /etc/init/ \
              /usr/share/fonts/ttf/ \
              ${sbindir} \
	      ${bindir} \
"
INSANE_SKIP:${PN} = "file-rdeps"
