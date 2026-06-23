SUMMARY = "Encryption handler for MYIR i.MX95 modules"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "\
    file://myir-enc.sh \
    file://myir-enc \
    file://myir-enc-handler.service \
    file://99-tpm.rules \
"

RDEPENDS:${PN} = "\
    openssl-bin \
    cryptsetup \
    e2fsprogs-mke2fs \
    keyutils \
    util-linux \
"

RDEPENDS_TPM = "tpm2-tools"

RDEPENDS:${PN}:append = "${@ ' ${RDEPENDS_TPM}' if d.getVar('MYIR_ENC_KEY_BACKEND') == 'tpm' else ''}"

inherit update-rc.d systemd

INITSCRIPT_NAME = "myir-enc"
INITSCRIPT_PARAMS = "start 30 1 2 3 4 5 . stop 80 0 6 ."

SYSTEMD_SERVICE:${PN} = "myir-enc-handler.service"

do_install() {
    install -d ${D}${sbindir}
    install -m 0755 ${UNPACKDIR}/myir-enc.sh ${D}${sbindir}/myir-enc.sh

    sed -i 's|@@MYIR_ENC_KEY_BACKEND@@|${MYIR_ENC_KEY_BACKEND}|g' ${D}${sbindir}/myir-enc.sh
    sed -i 's|@@MYIR_ENC_KEY_LOCATION@@|${MYIR_ENC_KEY_LOCATION}|g' ${D}${sbindir}/myir-enc.sh
    sed -i 's|@@MYIR_ENC_KEY_FILE@@|${MYIR_ENC_KEY_FILE}|g' ${D}${sbindir}/myir-enc.sh
    sed -i 's|@@MYIR_ENC_STORAGE_LOCATION@@|${MYIR_ENC_STORAGE_LOCATION}|g' ${D}${sbindir}/myir-enc.sh
    sed -i 's|@@MYIR_ENC_STORAGE_RESERVE@@|${MYIR_ENC_STORAGE_RESERVE}|g' ${D}${sbindir}/myir-enc.sh
    sed -i 's|@@MYIR_ENC_STORAGE_MOUNTPOINT@@|${MYIR_ENC_STORAGE_MOUNTPOINT}|g' ${D}${sbindir}/myir-enc.sh
    sed -i 's|@@MYIR_ENC_STORAGE_MKFS_ARGS@@|${MYIR_ENC_STORAGE_MKFS_ARGS}|g' ${D}${sbindir}/myir-enc.sh
    sed -i 's|@@MYIR_ENC_STORAGE_MOUNT_ARGS@@|${MYIR_ENC_STORAGE_MOUNT_ARGS}|g' ${D}${sbindir}/myir-enc.sh
    sed -i 's|@@MYIR_ENC_KEY_DIR@@|${MYIR_ENC_KEY_DIR}|g' ${D}${sbindir}/myir-enc.sh
    sed -i 's|@@MYIR_ENC_PRESERVE_DATA@@|${MYIR_ENC_PRESERVE_DATA}|g' ${D}${sbindir}/myir-enc.sh
    sed -i 's|@@MYIR_ENC_BACKUP_STORAGE_PCT@@|${MYIR_ENC_BACKUP_STORAGE_PCT}|g' ${D}${sbindir}/myir-enc.sh
    sed -i 's|@@MYIR_ENC_CIPHER@@|${MYIR_ENC_CIPHER}|g' ${D}${sbindir}/myir-enc.sh

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/myir-enc-handler.service ${D}${systemd_system_unitdir}

    if [ ${MYIR_ENC_KEY_BACKEND} = "tpm" ]; then
        dep_bef="Before=local-fs.target"
        dep_aft="After=systemd-remount-fs.service dev-tpm0.device"
        dep_req="Requires=dev-tpm0.device"
        dep_all="${dep_bef}\n${dep_aft}\n${dep_req}"
    elif [ ${MYIR_ENC_KEY_BACKEND} = "tee" ]; then
        dep_aft="After=tee-supplicant@teepriv0.service"
        dep_req="Requires=tee-supplicant@teepriv0.service"
        dep_all="${dep_aft}\n${dep_req}"
    else
        dep_bef="Before=local-fs.target"
        dep_aft="After=systemd-remount-fs.service"
        dep_all="${dep_bef}\n${dep_aft}"
    fi
    sed -i "/^@@DEPENDENCIES@@/c${dep_all}" ${D}${systemd_system_unitdir}/myir-enc-handler.service

    install -d ${D}${sysconfdir}/init.d
    install -m 755 ${UNPACKDIR}/myir-enc ${D}${sysconfdir}/init.d/myir-enc

    if [ ${MYIR_ENC_KEY_BACKEND} = "tpm" ]; then
        mkdir -p ${D}${sysconfdir}/udev/rules.d/
        install -m 0644 ${UNPACKDIR}/99-tpm.rules ${D}${sysconfdir}/udev/rules.d/99-tpm.rules
    fi
}
