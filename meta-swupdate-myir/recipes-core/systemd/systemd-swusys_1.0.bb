SUMMARY = "swupdate misc"
DESCRIPTION = "Use systemd service to implement the clean the upgrade_available, bootcount"
LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " file://clrupstatus.service "

inherit systemd

SYSTEMD_AUTO_ENABLE = "enable"
SYSTEMD_SERVICE:${PN} = "clrupstatus.service"

S = "${WORKDIR}/sources-unpack"

FILES:${PN} += "${systemd_unitdir}/system/clrupstatus.service"

do_install() {
  install -d ${D}/${systemd_unitdir}/system
  #install -m 0644 ${WORKDIR}/clrupstatus.service ${D}/${systemd_unitdir}/system
  install -m 0644 ${S}/clrupstatus.service ${D}${systemd_unitdir}/system/
}
