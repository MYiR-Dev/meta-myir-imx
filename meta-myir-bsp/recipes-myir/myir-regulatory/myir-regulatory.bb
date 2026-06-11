SUMMARY = "MYIR regulatory configs - touch/output mapping and USB quirks"
DESCRIPTION = "udev rules for dual-display touch mapping and USB device stability"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${THISDIR}/files/COPYING;md5=1c3a7fb45253c11c74434676d84fe7dd"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    file://80-touch-output.rules;subdir=${BP} \
    file://70-ilitek-usb-power.rules;subdir=${BP} \
    file://check-touch-mapping;subdir=${BP} \
    file://COPYING;subdir=${BP} \
"

PACKAGE_ARCH = "${MACHINE_ARCH}"

do_install() {

    install -d ${D}/usr/bin
    install -d ${D}/etc/udev/rules.d

    install -m 0755 ${S}/check-touch-mapping ${D}/usr/bin/

    install -m 0644 ${S}/80-touch-output.rules ${D}/etc/udev/rules.d/
    install -m 0644 ${S}/70-ilitek-usb-power.rules ${D}/etc/udev/rules.d/
}

FILES:${PN} += " \
    /usr/bin/check-touch-mapping \
    /etc/udev/rules.d/80-touch-output.rules \
    /etc/udev/rules.d/70-ilitek-usb-power.rules \
"
