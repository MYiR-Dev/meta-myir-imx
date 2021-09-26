SUMMARY = "fonts support"
DESCRIPTION = "myir fonts support"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"

S = "${WORKDIR}"

SRC_URI = "file://licenses/GPL-2 \
		   file://usr/lib/fonts/msyh.ttc \
          "
          

S = "${WORKDIR}"



				

do_install (){

	install -d ${D}${nonarch_libdir}/fonts


	

	install -m 755 ${WORKDIR}${nonarch_libdir}/fonts/msyh.ttc ${D}${nonarch_libdir}/fonts/msyh.ttc

	
}



FILES_${PN} = "/"
INSANE_SKIP_${PN} = "file-rdeps"
