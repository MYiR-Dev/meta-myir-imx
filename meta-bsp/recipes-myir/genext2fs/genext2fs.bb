SUMMARY = "genext2fs files"
DESCRIPTION = "genext2fs file"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"
PV = "0.1"
PR = "v1"

SRC_URI = "file://sbin/genext2fs \
           file://licenses/GPL-2 \
          "
          
S = "${WORKDIR}"

dirs755= "/sbin "

					

do_install (){
	for d in ${dirs755}; do
		install -m 0755 -d ${D}$d
	done
	
	install -m 0755 ${WORKDIR}/sbin/genext2fs ${D}/sbin/genext2fs

	
}



FILES_${PN} = "/"

