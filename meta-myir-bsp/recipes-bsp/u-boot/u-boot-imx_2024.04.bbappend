FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
FILES:${PN} += "${sysconfdir}/u-boot-initial-env ${sysconfdir}/u-boot-initial-env-sd"
do_install:append() {
    ln -sf u-boot-imx-initial-env-${MACHINE}-sd-${PV}-${PR} ${D}${sysconfdir}/u-boot-initial-env
    ln -sf u-boot-imx-initial-env-${MACHINE}-sd-${PV}-${PR} ${D}${sysconfdir}/u-boot-initial-env-sd
}
