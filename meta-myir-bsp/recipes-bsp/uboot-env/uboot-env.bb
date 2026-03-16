SUMMARY = "Myir tools V1.0.0"
DESCRIPTION = "MYIR Tools Configuration for MYIR boards"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"


inherit allarch

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://fw_env.config.${MACHINE};subdir=${BP}"



do_install() {
    install -d ${D}${sysconfdir}
    install -m 0644 ${S}/fw_env.config.${MACHINE} ${D}${sysconfdir}/fw_env.config
}

FILES:${PN} += "${sysconfdir}/fw_env.config"