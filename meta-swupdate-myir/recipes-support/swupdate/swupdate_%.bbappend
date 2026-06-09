FILESEXTRAPATHS:prepend := "${THISDIR}/files:${THISDIR}/swupdate:"

FILES:${PN} += "/www/*"

SRC_URI += " \
    file://swupdate-sysrestart.service \
    file://swupdate.cfg \
    file://swu_public.pem \
    file://0001-mongoose-enable-cgi.patch \
    file://sysinfo.cgi \
"

FILES:${PN} += " \
    ${systemd_system_unitdir}/swupdate-sysrestart.service \
"

RDEPENDS:${PN}-www += "bash"

SYSTEMD_SERVICE:${PN} += "swupdate-sysrestart.service"

do_install:append() {
    install -m 644 ${WORKDIR}/sources-unpack/swupdate.cfg ${D}${sysconfdir}/swupdate.cfg
    install -m 644 ${WORKDIR}/sources-unpack/swu_public.pem ${D}${sysconfdir}/swu_public.pem
    install -m 644 ${WORKDIR}/sources-unpack/swupdate-sysrestart.service ${D}${systemd_system_unitdir}/swupdate-sysrestart.service
    install -m 0755 ${WORKDIR}/sources-unpack/sysinfo.cgi ${D}/www/sysinfo.cgi
}
