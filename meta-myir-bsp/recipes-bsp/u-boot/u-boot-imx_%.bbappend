FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "${@bb.utils.contains('DISTRO_FEATURES', 'secure-boot', 'file://ahab.cfg', '', d)}"

UBOOT_CONFIG_FRAGMENT:append = "${@bb.utils.contains('DISTRO_FEATURES', 'secure-boot', ' ahab.cfg', '', d)}"
