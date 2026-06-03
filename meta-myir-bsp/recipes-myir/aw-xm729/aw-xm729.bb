SUMMARY = "NXP Wi-Fi driver for AW693/IW623"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://gpl-2.0.txt;md5=ab04ac0f249af12befccb94447c08b77"

FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI = "file://src"

S = "${WORKDIR}/src"
FW_DIR ?= "firmware"

inherit module

# Populate Module "moal" configure file as modprobe.d/moal.conf
KERNEL_MODULE_PROBECONF += "moal"
module_conf_moal = "options moal mod_para=nxp/wifi_mod_para.conf"

# Auto-loading module "moal" during boot
KERNEL_MODULE_AUTOLOAD += "moal"

EXTRA_OEMAKE = "KERNELDIR=${STAGING_KERNEL_BUILDDIR} -C ${STAGING_KERNEL_BUILDDIR} M=${S}"

do_install:append() {
    install -d ${D}${nonarch_base_libdir}/firmware/nxp
    install -m 0644 ${S}/${FW_DIR}/*.bin.se ${D}${nonarch_base_libdir}/firmware/nxp/
}

PACKAGES += "${PN}-firmware"

FILES:${PN}-firmware = "${nonarch_base_libdir}/firmware/nxp/*.bin.se"

RDEPENDS:${PN} += "${PN}-firmware"
