SUMMARY = "Factory eMMC burn package"
DESCRIPTION = "Boot from SD and burn full image to nand automatically"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=aaea0a512b56dbca7ab3c8e89d0696c6"

COMPATIBLE_MACHINE = "^(myd-y6ull-14x14-nand-256d|myd-y6ull-14x14-nand-512d)$"

inherit systemd
DUAL_ROOTFS ?=""
BURN_SCRIPT = "burn_nand_${MACHINE}${DUAL_ROOTFS}.sh"
ROOTFS_IMAGE ?= "myir-image-nand"

SRC_URI = " \
    file://home/root/${BURN_SCRIPT};subdir=${BP} \
    file://Manifest/${MACHINE}-Manifest;subdir=${BP} \
    file://fac-burn-nand.service;subdir=${BP} \
    file://licenses/GPL-2;subdir=${BP} \
"

do_install[depends] += "${ROOTFS_IMAGE}:do_image_complete"
do_install[depends] += "virtual/kernel:do_deploy"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -d ${D}${ROOT_HOME}/mfg-images

    # service
    install -m 0644 ${S}/fac-burn-nand.service \
        ${D}${systemd_system_unitdir}/

    # script
    install -m 0755 ${S}/home/root/${BURN_SCRIPT} \
        ${D}${ROOT_HOME}/burn_nand.sh

    #Manifest
    install -m 0644 ${S}/Manifest/${MACHINE}-Manifest \
        ${D}${ROOT_HOME}/mfg-images/

    # bootloader
    install -m 0644 ${DEPLOY_DIR_IMAGE}/u-boot.imx \
        ${D}${ROOT_HOME}/mfg-images/

    # kernel + dtb
    for i in ${IMAGE_BOOT_FILES}; do
        install -m 0644 ${DEPLOY_DIR_IMAGE}/${i} \
            ${D}${ROOT_HOME}/mfg-images/
    done

    # rootfs
    install -m 0644 \
        ${DEPLOY_DIR_IMAGE}/${ROOTFS_IMAGE}-${MACHINE}.rootfs.ubi \
        ${D}${ROOT_HOME}/mfg-images/
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "fac-burn-nand.service"
SYSTEMD_AUTO_ENABLE = "enable"

RDEPENDS:${PN} += "bash util-linux mtd-utils"


FILES:${PN} += " \
    ${ROOT_HOME}/burn_nand.sh \
    ${ROOT_HOME}/mfg-images \
    ${ROOT_HOME}/mfg-images/* \
"

INSANE_SKIP:${PN} += "buildpaths"
