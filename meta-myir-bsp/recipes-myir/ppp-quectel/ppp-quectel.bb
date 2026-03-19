SUMMARY = "PPP config file for Quectel EC20"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=012014e923710289dc42fed1dfa3a267"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

RDEPENDS:${PN} = "ppp"

SRC_URI = " \
    file://LICENSE;subdir=${BP} \
    file://quectel-dial;subdir=${BP} \
    file://quectel-chat-connect;subdir=${BP} \
    file://quectel-chat-disconnect;subdir=${BP} \
"

do_install () {

    install -d ${D}${sysconfdir}/ppp/chatscripts
    install -d ${D}${sysconfdir}/ppp/peers

    install -m 0755 ${S}/quectel-dial ${D}${sysconfdir}/ppp/peers/
    install -m 0755 ${S}/quectel-chat-connect ${D}${sysconfdir}/ppp/chatscripts/
    install -m 0755 ${S}/quectel-chat-disconnect ${D}${sysconfdir}/ppp/chatscripts/
}

FILES:${PN} += "${sysconfdir}/ppp"