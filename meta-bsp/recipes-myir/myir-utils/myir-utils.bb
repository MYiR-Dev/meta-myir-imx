SUMMARY = "myir utils 2.0"
DESCRIPTION = "myir utils application"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"

S = "${WORKDIR}"

SRC_URI = "file://licenses/GPL-2 \
		   file://usr/sbin/adl10-e \
		   file://usr/sbin/adl10-e_client \
                   file://etc/myir_test/myir_audio_play  \
                   file://etc/myir_test/myir_camera_play  \
                   file://etc/myir_test/myir_dial  \
                   file://etc/myir_test/wifi_on_ap  \
                   file://etc/myir_test/wifi_on_sta  \
		   file://20-static-usb0.network \
		   file://sw-version \
          "
          
inherit  systemd

S = "${WORKDIR}"
ROOT_HOME="/usr/sbin"


					

do_install (){
	install -d ${D}${systemd_system_unitdir}
	install -d ${D}${systemd_system_unitdir}/../network
	install -d ${D}${datadir}
	install -d ${D}${datadir}/myir
	install -d ${D}${datadir}/myir/Video
	install -d ${D}${datadir}/myir/Music
	install -d ${D}${datadir}/myir/Capture
	install -d ${D}${datadir}/fonts/ttf
	install -d ${D}${ROOT_HOME}
	install -d ${D}/etc
	install -d ${D}/etc/myir_test

        install -m 755 ${WORKDIR}/etc/myir_test/myir_audio_play ${D}/etc/myir_test
        install -m 755 ${WORKDIR}/etc/myir_test/myir_camera_play ${D}/etc/myir_test
        install -m 755 ${WORKDIR}/etc/myir_test/myir_dial ${D}/etc/myir_test
        install -m 755 ${WORKDIR}/etc/myir_test/wifi_on_ap ${D}/etc/myir_test
        install -m 755 ${WORKDIR}/etc/myir_test/wifi_on_sta ${D}/etc/myir_test	
	install -m 755 ${WORKDIR}${ROOT_HOME}/adl10-e ${D}${ROOT_HOME}/adl10-e
	install -m 755 ${WORKDIR}${ROOT_HOME}/adl10-e_client ${D}${ROOT_HOME}/adl10-e_client

	install -m 644 ${WORKDIR}/20-static-usb0.network ${D}${systemd_system_unitdir}/../network/20-static-usb0.network
	install -m 644 ${WORKDIR}/sw-version ${D}/etc/sw-version
	
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} = "/"
INSANE_SKIP:${PN} = "file-rdeps"
