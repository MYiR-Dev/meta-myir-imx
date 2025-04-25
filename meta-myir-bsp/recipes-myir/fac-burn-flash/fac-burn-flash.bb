SUMMARY = "for sdcard program"
DESCRIPTION = "use sdcard boot up and program full image to emmc"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"

inherit  systemd

S = "${WORKDIR}"

RDEPENDS:${PN} += "bash"

SRC_URI = "file://root/burn_flash.sh \
	   file://fac-burn-flash.service \
           file://licenses/GPL-2 \
          "

do_install(){
  install -d ${D}${systemd_system_unitdir}
	install -d ${D}/root/
	install -d ${D}/root/mfgimage
	install -d ${D}/root/mfgimage/kernel_dtb

	install -m 755 ${WORKDIR}/fac-burn-flash.service ${D}${systemd_system_unitdir}/fac-burn-flash.service

        install -m 755 ${WORKDIR}/root/burn_flash.sh ${D}/root/burn_flash.sh

        install -m 755 ${DEPLOY_DIR_IMAGE}/imx-boot ${D}/root/mfgimage/imx-boot

        for i in ${IMAGE_BOOT_FILES};do
                install -m 755 ${DEPLOY_DIR_IMAGE}/${i} ${D}/root/mfgimage/kernel_dtb/${i}
        done

        install -m 755 ${DEPLOY_DIR_IMAGE}/myir-image-full-${MACHINENAME}.rootfs.ext4  ${D}/root/mfgimage/rootfs-full.ext4
	
}


FILES:${PN} = "/"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "fac-burn-flash.service"
SYSTEMD_AUTO_ENABLE = "enable"
