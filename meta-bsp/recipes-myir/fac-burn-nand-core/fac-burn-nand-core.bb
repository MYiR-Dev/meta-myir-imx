SUMMARY = "for sdcard program"
DESCRIPTION = "use sdcard boot up and program full image to nand"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"

inherit  systemd

S = "${WORKDIR}"

SRC_URI = "file://home/root/burn_nand.sh \
	   file://fac-burn-nand.service \
           file://licenses/GPL-2 \
          "

do_install(){
  install -d ${D}${systemd_system_unitdir}
	install -d ${D}/home/root/
	install -d ${D}/home/root/mfgimage
	install -d ${D}/home/root/mfgimage/kernel_dtb

	install -m 755 ${WORKDIR}/fac-burn-nand.service ${D}${systemd_system_unitdir}/fac-burn-nand.service

	install -m 755 ${WORKDIR}/home/root/burn_nand.sh ${D}/home/root/burn_nand.sh
	install -m 755 ${DEPLOY_DIR_IMAGE}/u-boot.imx-nand ${D}/home/root/mfgimage/imx-boot

	for i in ${IMAGE_BOOT_FILES};do
		install -m 755 ${DEPLOY_DIR_IMAGE}/${i} ${D}/home/root/mfgimage/kernel_dtb/${i}
	done
	
    install -m 755 ${DEPLOY_DIR_IMAGE}/myir-image-core-${MACHINENAME}.ubi  ${D}/home/root/mfgimage/rootfs-core.ubi
}


FILES_${PN} = "/"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE_${PN} = "fac-burn-nand.service"
SYSTEMD_AUTO_ENABLE = "enable"
