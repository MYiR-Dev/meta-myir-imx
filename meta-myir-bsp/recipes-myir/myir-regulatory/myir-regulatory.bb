SUMMARY = "MYIR regulatory configs - touch/output mapping and USB quirks"
DESCRIPTION = "udev rules for dual-display touch mapping and USB device stability"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${THISDIR}/files/COPYING;md5=1c3a7fb45253c11c74434676d84fe7dd"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    file://80-touch-output.rules;subdir=${BP} \
    file://70-ilitek-usb-power.rules;subdir=${BP} \
    file://check-touch-mapping;subdir=${BP} \
    file://setup-touch-clone;subdir=${BP} \
    file://COPYING;subdir=${BP} \
"
SRC_URI:append:myd-js8mpq = " file://setup-touch-clone-js8mp;subdir=${BP}"

PACKAGE_ARCH = "${MACHINE_ARCH}"

do_install() {

    install -d ${D}/usr/bin
    install -d ${D}/etc/udev/rules.d
    install -d ${D}/etc/systemd/system/weston.service.d

    install -m 0755 ${S}/check-touch-mapping ${D}/usr/bin/
    install -m 0755 ${S}/setup-touch-clone ${D}/usr/bin/

    install -m 0644 ${S}/80-touch-output.rules ${D}/etc/udev/rules.d/
    install -m 0644 ${S}/70-ilitek-usb-power.rules ${D}/etc/udev/rules.d/

    # systemd drop-in: run setup-touch-clone before Weston starts
    echo "[Service]" > ${D}/etc/systemd/system/weston.service.d/touch-clone.conf
    echo "ExecStartPre=-/usr/bin/setup-touch-clone" >> ${D}/etc/systemd/system/weston.service.d/touch-clone.conf
}

# MYD-JS8MPQ uses an isolated dual-single-link LVDS implementation.  Keep the
# board-specific clone policy out of the common helper and select it only
# through this exact MACHINE override.
do_install:append:myd-js8mpq() {
    install -m 0755 ${S}/setup-touch-clone-js8mp ${D}/usr/bin/

    echo "[Service]" > ${D}/etc/systemd/system/weston.service.d/touch-clone.conf
    echo "ExecStartPre=-/usr/bin/setup-touch-clone-js8mp" >> ${D}/etc/systemd/system/weston.service.d/touch-clone.conf
}

FILES:${PN} += " \
    /usr/bin/check-touch-mapping \
    /usr/bin/setup-touch-clone \
    /etc/udev/rules.d/80-touch-output.rules \
    /etc/udev/rules.d/70-ilitek-usb-power.rules \
    /etc/systemd/system/weston.service.d/touch-clone.conf \
"

FILES:${PN}:append:myd-js8mpq = " /usr/bin/setup-touch-clone-js8mp"
