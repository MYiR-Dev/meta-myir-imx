SUMMARY = "PPP config file for Quectel EC20"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS_${PN} = "ppp"

S = "${WORKDIR}"

SRC_URI += " \
    file://quectel-dial \
    file://quectel-chat-connect \
    file://quectel-chat-disconnect"

do_install () {
    install -d ${D}${sysconfdir}/ppp/chatscripts
    install -d ${D}${sysconfdir}/ppp/peers
    install -m 0755 quectel-dial ${D}${sysconfdir}/ppp/peers/
    install -m 0755 quectel-chat-connect ${D}${sysconfdir}/ppp/chatscripts/
    install -m 0755 quectel-chat-disconnect ${D}${sysconfdir}/ppp/chatscripts/
}

FILES_${PN} += "${sysconfdir}/ppp/"
FILES_${PN} += "${sysconfdir}/ppp/peers/"
FILES_${PN} += "${sysconfdir}/ppp/chatscripts"
