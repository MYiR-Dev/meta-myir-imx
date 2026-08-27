SUMMARY = "MYD-JS8MPQ CAAM tagged-key dm-crypt data volume"
DESCRIPTION = "Provisions a device-bound CAAM black blob and mounts encdata through dm-crypt."

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://myd-js8mpq-caam-dmcrypt.sh \
    file://myd-js8mpq-caam-dmcrypt.service \
"

inherit systemd

RDEPENDS:${PN} = " \
    e2fsprogs-mke2fs \
    keyutils \
    lvm2 \
    myd-js8mpq-caam-keygen \
    util-linux \
    util-linux-blkid \
    util-linux-blockdev \
    util-linux-mount \
    util-linux-mountpoint \
    util-linux-umount \
"

do_install() {
    install -d ${D}${sbindir}
    install -m 0755 ${UNPACKDIR}/myd-js8mpq-caam-dmcrypt.sh \
        ${D}${sbindir}/myd-js8mpq-caam-dmcrypt

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/myd-js8mpq-caam-dmcrypt.service \
        ${D}${systemd_system_unitdir}/

    install -d ${D}/data
}

SYSTEMD_SERVICE:${PN} = "myd-js8mpq-caam-dmcrypt.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} += "${sbindir}/myd-js8mpq-caam-dmcrypt /data"

COMPATIBLE_MACHINE = "^myd-js8mpq$"
