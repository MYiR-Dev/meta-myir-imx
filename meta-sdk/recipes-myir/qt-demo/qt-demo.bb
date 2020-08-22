
inherit systemd

DESCRIPTION = "qt app"
DEPENDS = "zlib glibc ncurses "
SECTION = "libs"
LICENSE = "MIT"
PV = "3"
PR = "r0"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"


SRC_URI = " \ 
	    file://start.sh \
	    file://myir.service \
	    file://fonts \
	    file://files \
	    file://Capture \
	    file://Music \
	    file://Video \
	    file://ecg \
	    file://mxapp2 \
	    file://lib \
          "
S_G = "${WORKDIR}"

do_install () {
      install -d ${D}/lib/systemd/system/
      install -d ${D}/usr/lib/fonts/
      install -d ${D}/usr/bin/
      install -d ${D}/usr/lib/
      install -d ${D}/home/
      install -d ${D}/usr/share/myir/
      install -d ${D}/usr/share/myir/Music/
      install -d ${D}/usr/share/myir/Capture/
      install -d ${D}/usr/share/myir/Video/

      cp -r ${S_G}/start.sh ${D}/usr/bin/
      install -m 0644 ${S_G}/myir.service ${D}/lib/systemd/system/
      cp -r ${S_G}/fonts/* ${D}/usr/lib/fonts/
      cp -r ${S_G}/files/* ${D}/usr/bin/
      cp -r ${S_G}/lib/* ${D}/usr/lib/
      cp -r ${S_G}/ecg/* ${D}/usr/share/myir/
      cp -r ${S_G}/Music/* ${D}/usr/share/myir/Music/
      cp -r ${S_G}/Capture/* ${D}/usr/share/myir/Capture/
      cp -r ${S_G}/Video/* ${D}/usr/share/myir/Video/

}

FILES_${PN} = "\
	     /usr/bin/ \
	     /usr/lib/fonts/ \
             /usr/share/fonts/ttf/ \
	     /lib/systemd/system/ \
	     /usr/lib/ \
	     /home/ \
	     /usr/share/myir/ \
             /usr/share/myir/Music/ \
	     /usr/share/myir/Capture/ \
	    /usr/share/myir/Video/ \
             "

#For dev packages only
INSANE_SKIP_${PN}-dev = "ldflags"
INSANE_SKIP_${PN} = "${ERROR_QA} ${WARN_QA}"
SYSTEMD_SERVICE_${PN} = "myir.service"
SYSTEMD_AUTO_ENABLE_${PN} = "enable"
