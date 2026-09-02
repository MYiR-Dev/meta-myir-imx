FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
FILESEXTRAPATHS:prepend:myd-js8mpq := "${THISDIR}/${BPN}/myd-js8mpq:"
SRC_URI += "file://defconfig"
SRC_URI += "file://swu_public.pem"
SRC_URI += "file://swupdate.cfg"

DEPENDS:append = " gpgme"

# Keep the version policy in the target image synchronized with the version
# embedded in sw-description. The older image keeps its old threshold until
# the new rootfs has been installed and rebooted.
do_install:append:myd-js8mpq() {
    install -d ${D}${sysconfdir}
    sed -e "s/__MYIR_RELEASE_VERSION__/${MYIR_RELEASE_VERSION}/g" \
        ${WORKDIR}/sources-unpack/swupdate.cfg \
        > ${D}${sysconfdir}/swupdate.cfg
}
