SUMMARY = "Factory eMMC burn package"
DESCRIPTION = "Boot from SD and burn full image to eMMC automatically"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"

COMPATIBLE_MACHINE = "^(myd-js8mpq|myd-lmx9x-11x11|myd-y6ull-14x14-emmc|myd-jmx95-15x15-lpddr5)$"

inherit systemd
DUAL_ROOTFS ?=""
SIGNED_BOOT ?=""
ROOTFS_IMAGE ?= "myir-image-emmc"
DM_VERITY_IMAGE ?= ""

SRC_URI = " \
    file://home/root/${BURN_SCRIPT};subdir=${BP} \
    file://fac-burn-emmc.service;subdir=${BP} \
    file://licenses/GPL-2;subdir=${BP} \
"
BOOT_IMAGE_NAME = "${@'imx-boot-signed' if d.getVar('DM_VERITY_IMAGE') or d.getVar('SIGNED_BOOT') == 'signed' else 'imx-boot'}"
BOOT_IMAGE_NAME:mx6ull-generic-bsp = "u-boot.imx"
# MYD-JS8MPQ HAB signing publishes the selected signed/unsigned container
# through the common imx-boot deploy name.
BOOT_IMAGE_NAME:myd-js8mpq = "imx-boot"

BOOT_IMAGE_DEST ?= "imx-boot"
BOOT_IMAGE_DEST:mx6ull-generic-bsp = "u-boot.imx"
BURN_SCRIPT = "${@'burn_emmc_%s_verity.sh' % d.getVar('MACHINE') \
               if d.getVar('DM_VERITY_IMAGE') \
               else ('burn_emmc_%s_%s.sh' % (d.getVar('MACHINE'), d.getVar('DUAL_ROOTFS') or '')) \
               if d.getVar('SIGNED_BOOT') == 'signed' \
               else 'burn_emmc_%s.sh' % d.getVar('MACHINE')}"
BURN_SCRIPT:myd-js8mpq = "${@'burn_emmc_myd-js8mpq_verity.sh' \
                              if d.getVar('DM_VERITY_IMAGE') \
                              else 'burn_emmc_myd-js8mpq_dual_crypt.sh' \
                              if d.getVar('MYD_JS8MPQ_CAAM_DMCRYPT') == '1' \
                              else 'burn_emmc_myd-js8mpq_dual.sh' \
                              if d.getVar('OTA_SUPPORT') == '1' \
                              else 'burn_emmc_myd-js8mpq.sh'}"

python () {
    if d.getVar('MACHINE') != 'myd-js8mpq':
        return
    if d.getVar('MYD_JS8MPQ_CAAM_DMCRYPT') != '1':
        return
    if d.getVar('OTA_SUPPORT') != '1':
        bb.fatal('MYD_JS8MPQ_CAAM_DMCRYPT=1 requires OTA_SUPPORT=1 for the A/B + encdata layout')
    if d.getVar('DM_VERITY_IMAGE'):
        bb.fatal('The MYD-JS8MPQ CAAM dm-crypt test layout cannot be combined with DM_VERITY_IMAGE yet')
    size = d.getVar('MYD_JS8MPQ_CAAM_DMCRYPT_DATA_SIZE_MIB') or ''
    if not size.isdigit() or int(size) < 16:
        bb.fatal('MYD_JS8MPQ_CAAM_DMCRYPT_DATA_SIZE_MIB must be an integer of at least 16 MiB')
}

DM_VERITY_IMAGE_TYPE ?= "ext4"
ROOTFS_SRC_FILE = "${@d.getVar('DM_VERITY_IMAGE') + '-' + d.getVar('MACHINE') + '.' + d.getVar('DM_VERITY_IMAGE_TYPE') + '.verity' if d.getVar('DM_VERITY_IMAGE') else d.getVar('ROOTFS_IMAGE') + '-' + d.getVar('MACHINE') + '.rootfs.ext4'}"


do_install[depends] += "${ROOTFS_IMAGE}:do_image_complete"
do_install[depends] += "virtual/kernel:do_deploy"
do_install[depends] += "${@'${DM_VERITY_IMAGE}:do_image_complete' if d.getVar('DM_VERITY_IMAGE') else ''}"
# The burn image already pulls in myir-image-emmc through its image
# composition. Remove the reverse dependency only for MYD-JS8MPQ to avoid a
# dependency cycle; keep the original dependency for all other machines.
python __anonymous () {
    if d.getVar('MACHINE') == 'myd-js8mpq':
        depends = d.getVarFlag('do_install', 'depends', expand=False) or ''
        rootfs_dep = '%s:do_image_complete' % (d.getVar('ROOTFS_IMAGE') or '')
        depends = depends.replace('${ROOTFS_IMAGE}:do_image_complete', '')
        depends = depends.replace(rootfs_dep, '')
        d.setVarFlag('do_install', 'depends', ' '.join(depends.split()))
}

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -d ${D}${ROOT_HOME}/mfgimage/kernel_dtb

    # service
    install -m 0644 ${S}/fac-burn-emmc.service \
        ${D}${systemd_system_unitdir}/

    # script
    install -m 0755 ${S}/home/root/${BURN_SCRIPT} \
        ${D}${ROOT_HOME}/burn_emmc.sh
    if [ "${MACHINE}" = "myd-js8mpq" ] &&
       [ "${MYD_JS8MPQ_CAAM_DMCRYPT}" = "1" ]; then
        sed -i \
            's|@@ENCDATA_SIZE_MIB@@|${MYD_JS8MPQ_CAAM_DMCRYPT_DATA_SIZE_MIB}|g' \
            ${D}${ROOT_HOME}/burn_emmc.sh
    fi

    # bootloader
    install -m 0644 ${DEPLOY_DIR_IMAGE}/${BOOT_IMAGE_NAME} \
        ${D}${ROOT_HOME}/mfgimage/${BOOT_IMAGE_DEST}

    # kernel + dtb
    for i in ${@" ".join(item.split(";")[0] for item in d.getVar("IMAGE_BOOT_FILES").split())}; do
        install -m 0644 ${DEPLOY_DIR_IMAGE}/${i} \
            ${D}${ROOT_HOME}/mfgimage/kernel_dtb/
    done

    # rootfs -- dm-verity / normal
    if [ -n "${DM_VERITY_IMAGE}" ]; then
        bbnote "myir-fac-burn: deploying dm-verity rootfs"
        for f in ${DEPLOY_DIR_IMAGE}/${DM_VERITY_IMAGE}-${MACHINE}*.${DM_VERITY_IMAGE_TYPE}.verity; do
            if [ -f "$f" ]; then
                install -m 0644 "$f" ${D}${ROOT_HOME}/mfgimage/rootfs-full.verity
                bbnote "myir-fac-burn: verity rootfs deployed from $f"
                break
            fi
        done
        [ -f ${D}${ROOT_HOME}/mfgimage/rootfs-full.verity ] || \
            bbfatal ".verity file not found in DEPLOY_DIR_IMAGE for ${DM_VERITY_IMAGE}-${MACHINE}"
    else
        install -m 0644 \
            ${DEPLOY_DIR_IMAGE}/${ROOTFS_IMAGE}-${MACHINE}.rootfs.ext4 \
            ${D}${ROOT_HOME}/mfgimage/rootfs-full.ext4
    fi
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "fac-burn-emmc.service"
SYSTEMD_AUTO_ENABLE = "enable"

RDEPENDS:${PN} += "bash e2fsprogs-resize2fs util-linux"
RDEPENDS:${PN}:append:myd-js8mpq = "${@' dosfstools e2fsprogs-e2fsck mmc-utils util-linux-blkdiscard util-linux-blockdev util-linux-findmnt util-linux-mount util-linux-partx util-linux-sfdisk util-linux-umount' if d.getVar('MYD_JS8MPQ_CAAM_DMCRYPT') == '1' else ''}"


FILES:${PN} += " \
    ${ROOT_HOME}/burn_emmc.sh \
    ${ROOT_HOME}/mfgimage \
    ${ROOT_HOME}/mfgimage/* \
"

INSANE_SKIP:${PN} += "buildpaths"
