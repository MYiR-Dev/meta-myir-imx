SUMMARY = "quectel ec20 ppp script and qmi_wwan for RM500Q-L module"
DESCRIPTION = "ppp script and qmi_wwan script"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"
PV = "0.1"
PR = "v1"
INSANE_SKIP_${PN} = "file-rdeps"

SRC_URI = "file://licenses/GPL-2 \
					 file://sbin/chat \
           file://sbin/pppd \
           file://sbin/quectel-CM \
           file://etc/ppp/ip-up \
           file://etc/ppp/peers/quectel-chat-connect \
           file://etc/ppp/peers/quectel-chat-disconnect \
           file://etc/ppp/peers/quectel-ppp \
          "
          
S = "${WORKDIR}"

dirs755= "${sysconfdir} \
					${sysconfdir}/ppp \
					${sysconfdir}/ppp/peers \
					${sbindir}"
					

do_install (){
	for d in ${dirs755}; do
		install -m 0755 -d ${D}$d
	done
	
	install -m 0755 ${WORKDIR}/sbin/chat ${D}${sbindir}
	install -m 0755 ${WORKDIR}/sbin/pppd ${D}${sbindir}
	install -m 0755 ${WORKDIR}/sbin/quectel-CM ${D}${sbindir}
	install -m 0755 ${WORKDIR}/etc/ppp/ip-up ${D}${sysconfdir}/ppp/
	install -m 0755 ${WORKDIR}/etc/ppp/peers/quectel-chat-connect ${D}${sysconfdir}/ppp/peers/
	install -m 0755 ${WORKDIR}/etc/ppp/peers/quectel-chat-disconnect ${D}${sysconfdir}/ppp/peers/
	install -m 0755 ${WORKDIR}/etc/ppp/peers/quectel-ppp ${D}${sysconfdir}/ppp/peers/
	
}



FILES_${PN} = "/"

