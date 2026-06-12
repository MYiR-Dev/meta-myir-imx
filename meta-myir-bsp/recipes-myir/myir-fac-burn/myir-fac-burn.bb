SUMMARY = "Factory eMMC burn package"
DESCRIPTION = "Boot from SD and burn full image to eMMC automatically"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"

inherit systemd
DUAL_ROOTFS ?=""
SIGNED_BOOT ?=""
ROOTFS_IMAGE ?= "myir-image-emmc"

SRC_URI = " \
    file://home/root/${BURN_SCRIPT};subdir=${BP} \
    file://fac-burn-emmc.service;subdir=${BP} \
    file://licenses/GPL-2;subdir=${BP} \
"
BOOT_IMAGE_NAME = "${@'imx-boot-signed' if d.getVar('SIGNED_BOOT') == 'signed' else 'imx-boot'}"
BURN_SCRIPT = "${@('burn_emmc_%s_%s.sh' % (d.getVar('MACHINE'), d.getVar('DUAL_ROOTFS') or '')) if d.getVar('SIGN_BOOT') == 'signed' else ('burn_emmc_%s.sh' % d.getVar('MACHINE'))}"


do_install[depends] += "${ROOTFS_IMAGE}:do_image_complete"
do_install[depends] += "virtual/kernel:do_deploy"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -d ${D}${ROOT_HOME}/mfgimage/kernel_dtb

    # service
    install -m 0644 ${S}/fac-burn-emmc.service \
        ${D}${systemd_system_unitdir}/

    # script
    install -m 0755 ${S}/home/root/${BURN_SCRIPT} \
        ${D}${ROOT_HOME}/burn_emmc.sh

    # bootloader
    install -m 0644 ${DEPLOY_DIR_IMAGE}/${BOOT_IMAGE_NAME} \
        ${D}${ROOT_HOME}/mfgimage/

    # kernel + dtb
    for i in ${IMAGE_BOOT_FILES}; do
        install -m 0644 ${DEPLOY_DIR_IMAGE}/${i} \
            ${D}${ROOT_HOME}/mfgimage/kernel_dtb/
    done

    # rootfs
    install -m 0644 \
        ${DEPLOY_DIR_IMAGE}/${ROOTFS_IMAGE}-${MACHINE}.rootfs.ext4 \
        ${D}${ROOT_HOME}/mfgimage/rootfs-full.ext4
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "fac-burn-emmc.service"
SYSTEMD_AUTO_ENABLE = "enable"

RDEPENDS:${PN} += "bash e2fsprogs-resize2fs util-linux"


FILES:${PN} += " \
    ${ROOT_HOME}/burn_emmc.sh \
    ${ROOT_HOME}/mfgimage \
    ${ROOT_HOME}/mfgimage/* \
"

INSANE_SKIP:${PN} += "buildpaths"
