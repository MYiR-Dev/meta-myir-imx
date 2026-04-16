FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
SRC_URI += "file://defconfig"
SRC_URI += "file://swu_public.pem"
SRC_URI += "file://swupdate.cfg"

DEPENDS:append = " gpgme"