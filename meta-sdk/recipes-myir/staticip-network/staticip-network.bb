# MYIR - 2020   Alex .
DESCRIPTION = "Extra files for MYiR"
LICENSE = "LGPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=309cc7bace8769cfabdd34577f654f8e"

SRC_URI = " \
           file://LICENSE \
	   file://10-static-eth0.network \
	   file://11-static-eth1.network \
          "

S = "${WORKDIR}"

do_install () {
    install -d ${D}/${sysconfdir}/
    install -d ${D}/${sysconfdir}/systemd/network/
    install -m 755 ${S}/10-static-eth0.network  ${D}/${sysconfdir}/systemd/network/
    install -m 755 ${S}/11-static-eth1.network  ${D}/${sysconfdir}/systemd/network/
}

INSANE_SKIP_${PN}-dev = "ldflags"
INSANE_SKIP_${PN} = "${ERROR_QA} ${WARN_QA}"
