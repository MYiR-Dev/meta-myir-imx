SUMMARY = "Auto wifi ap and sta"
DESCRIPTION = "Script to connect wifi sta and ap for MYIR boards"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${THISDIR}/files/COPYING;md5=1c3a7fb45253c11c74434676d84fe7dd"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    file://ifup_wifi_ap;subdir=${BP} \
    file://ifup_wifi_sta;subdir=${BP} \
    file://ifup_wifi_forward;subdir=${BP} \
    file://myir_hostapd.conf;subdir=${BP} \
    file://myir_udhcpd.conf;subdir=${BP} \
    file://moal-sta-name.conf;subdir=${BP} \
    file://70-wifi-rename.rules;subdir=${BP} \
    file://COPYING;subdir=${BP} \
"

PACKAGE_ARCH = "${MACHINE_ARCH}"

do_install() {

    install -d ${D}/usr/bin
    install -d ${D}/etc
    install -d ${D}/etc/modprobe.d
    install -d ${D}/etc/udev/rules.d

    install -m 0755 ${S}/ifup_wifi_ap ${D}/usr/bin/
    install -m 0755 ${S}/ifup_wifi_sta ${D}/usr/bin/
    install -m 0755 ${S}/ifup_wifi_forward ${D}/usr/bin/

    install -m 0644 ${S}/myir_hostapd.conf ${D}/etc/
    install -m 0644 ${S}/myir_udhcpd.conf ${D}/etc/

    install -m 0644 ${S}/moal-sta-name.conf ${D}/etc/modprobe.d/
    install -m 0644 ${S}/70-wifi-rename.rules ${D}/etc/udev/rules.d/
}

FILES:${PN} += " \
    /usr/bin/ifup_wifi_ap \
    /usr/bin/ifup_wifi_sta \
    /usr/bin/ifup_wifi_forward \
    /etc/myir_hostapd.conf \
    /etc/myir_udhcpd.conf \
    /etc/modprobe.d/moal-sta-name.conf \
    /etc/udev/rules.d/70-wifi-rename.rules \
"