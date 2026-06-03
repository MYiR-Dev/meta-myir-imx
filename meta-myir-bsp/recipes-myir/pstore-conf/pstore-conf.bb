SUMMARY = "Pstore configuration file"
DESCRIPTION = "Install the pstore_blk configuration file"

LICENSE = "CLOSED"
PV = "0.1"
PR = "r1"

DEPENDS += "systemd"
inherit systemd

SRC_URI = " \
		file://etc/modprobe.d/pstore_blk.conf \
		file://etc/modules-load.d/pstore_blk.conf \
"

do_install (){
	install -d ${D}/etc
	install -d ${D}/etc/modprobe.d
	install -d ${D}/etc/modules-load.d

	install -m 0755 ${UNPACKDIR}/etc/modprobe.d/pstore_blk.conf        ${D}/etc/modprobe.d/pstore_blk.conf
	install -m 0755 ${UNPACKDIR}/etc/modules-load.d/pstore_blk.conf    ${D}/etc/modules-load.d/pstore_blk.conf
}

FILES:${PN} = "\
		/etc \
		/etc/modprobe.d \
		/etc/modules-load.d \
"

