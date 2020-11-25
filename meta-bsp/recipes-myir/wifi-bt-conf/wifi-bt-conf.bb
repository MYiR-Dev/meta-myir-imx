SUMMARY = "wifi&bt configure files"
DESCRIPTION = "wifi/bt files"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"
PV = "0.1"
PR = "v1"

SRC_URI = " \
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
	
	install -m 0644 ${WORKDIR}/etc/udhcpd.conf ${D}/etc/
	install -m 0755 ${WORKDIR}/usr/bin/brcm_patchram_plus ${D}/usr/bin
	install -m 0755 ${WORKDIR}/usr/bin/ifup_wifi_ap ${D}/usr/bin
	install -m 0755 ${WORKDIR}/usr/bin/ifup_wifi_sta ${D}/usr/bin
}

FILES_${PN} = "/"

