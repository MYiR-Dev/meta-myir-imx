# MYIR - 2020   Alex .
DESCRIPTION = "QT-DEMO for MYiR"

inherit systemd
inherit qmake5
inherit gettext
inherit pythonnative
inherit perlnative
inherit distro_features_check

#DEPENDS = "zlib glibc ncurses qtbase  "
DEPENDS = "zlib glibc ncurses qtbase qtquickcontrols qtquickcontrols2 qtmultimedia  "
SECTION = "libs"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRCREV = "51219782e64843f2090563ff4b7402b6d6faa809"
HMIV2_BRANCH ?= "hmi2.0-imx6ulx-gw-nogpu"
HMIV2_SRC ?= "git://github.com/MYiR-Dev/mxapp.git;protocol=https" 

## github link
SRC_URI += "${HMIV2_SRC};branch=${HMIV2_BRANCH} \
"

## local files
SRC_URI +=" \
      file://start.sh \
      file://myir.service \
      file://fonts \
      file://files \
      file://Capture \
      file://Music \
      file://ecg \
      file://lib \
"

S_G = "${WORKDIR}"
S = "${WORKDIR}/git"

## compile qt demo
do_compile[progress] = "outof:^\[(\d+)/(\d+)\]\s+"


dirinstall=" \
      ${bindir} \
      ${libdir} \
      ${libdir}/fonts/ \
      /usr/share/fonts/ttf/ \
      /home/ \
      /home/root \
      /usr/share/myir/ \
      /usr/share/myir/Music/ \
      /usr/share/myir/Capture/ \
      /usr/share/myir/Video/ \
      ${systemd_unitdir}/system \
"

do_install () {
      ## 
      for d in ${dirinstall}; do
            install -m 0755 -d ${D}$d
      done

      cp -r ${WORKDIR}/fonts/* ${D}${libdir}/fonts/
      cp -r ${WORKDIR}/files/* ${D}${bindir} 
      cp -r ${WORKDIR}/lib/* ${D}${libdir}
      cp -r ${WORKDIR}/ecg/* ${D}/usr/share/myir/
      cp -r ${WORKDIR}/Music/* ${D}/usr/share/myir/Music/
      cp -r ${WORKDIR}/Capture/* ${D}/usr/share/myir/Capture/

      install -m 755 ${WORKDIR}/start.sh ${D}${bindir} 
      install -m 0644 ${WORKDIR}/myir.service ${D}${systemd_system_unitdir}
      install -m 755 ${WORKDIR}/build/mxapp2 ${D}/home/root/
}

SYSTEMD_SERVICE_${PN} = "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'myir.service', '', d)}"

pkg_postinst_ontarget_${PN} () {
	if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
		if [ -n "$D" ]; then
			OPTS="--root=$D"
		fi
		systemctl $OPTS enable myir.service
	fi
}

FILES_${PN} = " \
            ${dirinstall} \
            "

#For dev packages only
INSANE_SKIP_${PN}-dev = "ldflags"
INSANE_SKIP_${PN} = "${ERROR_QA} ${WARN_QA}"
