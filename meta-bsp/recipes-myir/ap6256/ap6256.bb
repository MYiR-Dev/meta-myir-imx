SUMMARY = "ap6256 configure files"
DESCRIPTION = "ap6256 wifi/bt files"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"
PV = "0.1"
PR = "v1"

SRC_URI = "file://lib/firmware/bcmd/fw_bcm43456c5_ag.bin \
					 file://lib/firmware/bcmd/fw_bcm43456c5_ag_apsta.bin \
					 file://lib/firmware/bcmd/nvram_ap6256.txt \
					 file://lib/firmware/bcmd/BCM4345C5_AP6256_CL1.hcd \
					 file://usr/bin/brcm_patchram_plus \
					 file://usr/bin/ifup_wifi_sta \
					 file://usr/bin/ifup_wifi_ap \
					 file://etc/udhcpd.conf \
           file://licenses/GPL-2 \
          "
          
S = "${WORKDIR}"

dirs755= "/lib/firmware/bcmd/ \
					/usr/bin \
					/etc/"

					

do_install (){
	for d in ${dirs755}; do
		install -m 0755 -d ${D}$d
	done
	
	install -m 0644 ${WORKDIR}/lib/firmware/bcmd/fw_bcm43456c5_ag.bin ${D}/lib/firmware/bcmd
	install -m 0644 ${WORKDIR}/lib/firmware/bcmd/fw_bcm43456c5_ag_apsta.bin ${D}/lib/firmware/bcmd
	install -m 0644 ${WORKDIR}/lib/firmware/bcmd/nvram_ap6256.txt ${D}/lib/firmware/bcmd
	install -m 0644 ${WORKDIR}/lib/firmware/bcmd/BCM4345C5_AP6256_CL1.hcd ${D}/lib/firmware/bcmd
	install -m 0644 ${WORKDIR}/etc/udhcpd.conf ${D}/etc/
	install -m 0755 ${WORKDIR}/usr/bin/brcm_patchram_plus ${D}/usr/bin
	install -m 0755 ${WORKDIR}/usr/bin/ifup_wifi_ap ${D}/usr/bin
	install -m 0755 ${WORKDIR}/usr/bin/ifup_wifi_sta ${D}/usr/bin
}



FILES_${PN} = "/"

