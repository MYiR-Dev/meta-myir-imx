SUMMARY = "wifi driver for RTL8188FU on MYS6ULx board"
LICENSE = "GPLv2"
PV = "0.1"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"


SRCREV = "471fb39418272ee52025235b8d38de02124ab112"
#SRC_URI = "git://github.com/whistmazel/rtl8188fu.git;protocol=https;branch=L5.10.9" 
#SRC_URI = "git:///media/liao/Linux_5.10.9/wifi-driver/rtl8188fu_linux_5.10.9;protocol=file;branch=L5.10.9"
S = "${WORKDIR}/git"

inherit module

do_install_append() {
    install -d ${D}${base_libdir}/firmware/rtlwifi
}

FILES_${PN} += " \
    ${base_libdir}/firmware \
    ${base_libdir}/firmware/rtlwifi \
    ${base_libdir}/firmware/rtlwifi/rtl8188fu.bin \
"

# The inherit of module.bbclass will automatically name module packages with
# "kernel-module-" prefix as required by the oe-core build environment.
COMPATIBLE_MACHINE = "(odm-sds)"
