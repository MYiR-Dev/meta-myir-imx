SUMMARY = "myir hmi 2.0"
DESCRIPTION = "myir hdmi 2.0 qt application"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"

S = "${WORKDIR}"

SRC_URI = "file://licenses/GPL-2 \
		   file://home/root/mxapp2 \
		   file://usr/lib/fonts/msyh.ttc \
		   file://usr/share/myir/ecg.dat \
		   file://usr/share/myir/resp.text \
		   file://myir_logo.png \
          "
          


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
	install -d ${D}${bindir}

	
	install -m 755 ${WORKDIR}${nonarch_libdir}/fonts/msyh.ttc ${D}${nonarch_libdir}/fonts/msyh.ttc
	install -m 755 ${WORKDIR}${datadir}/myir/ecg.dat ${D}${datadir}/myir/ecg.dat
	install -m 755 ${WORKDIR}${datadir}/myir/resp.text ${D}${datadir}/myir/resp.text


  install -d -m 755 ${D}/home/root/.myir_demo
  install -d -m 755 ${D}/home/root/.myir_demo/icon
  install -m 755 ${WORKDIR}/${ROOT_HOME}/mxapp2  ${D}${bindir}/mxapp2
	install -m 755 ${WORKDIR}/myir_logo.png ${D}/home/root/.myir_demo/icon/myir_logo.png


}


FILES_${PN} = "/"
INSANE_SKIP_${PN} = "file-rdeps"
