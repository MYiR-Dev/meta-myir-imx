FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
SRC_URI += "file://defconfig"
DEPENDS:append = " gpgme"