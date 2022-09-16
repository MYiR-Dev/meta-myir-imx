DESCRIPTION = "u-boot fw env and lib"
LICENSE = "LGPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=309cc7bace8769cfabdd34577f654f8e"

SRC_URI += " \
		file://fw_env.config \
		file://pcie2screen  \
 		file://usr \
		file://LICENSE \
		file://pcie_resume \
"
S="${WORKDIR}"

do_install() {
        install -d ${D}/usr/bin
	install -d ${D}/usr/lib
	install -d ${D}/usr/include
	install -d ${D}/lib/systemd/system-sleep/
        install -d ${D}${sysconfdir}
        install -m 755 ${S}/usr/bin/* ${D}/usr/bin
	install -m 755 ${S}/pcie2screen ${D}/usr/bin
	install -m 755 ${S}/pcie_resume ${D}/lib/systemd/system-sleep/
        cp -rf ${S}/usr/lib/* ${D}/usr/lib
        install -m 755 ${S}/usr/include/* ${D}/usr/include
        install -m 0644 ${S}/fw_env.config ${D}${sysconfdir}/fw_env.config

	cd ${D}/usr/lib
	ln -sf libriffa.so.1.0 libriffa.so.1
	ln -sf libubootenv.so.0.3.1 libubootenv.so 
}

FILES_${PN}=" /usr/bin   \
              /usr/lib   \
	      /usr/include \
	     /lib/systemd/system-sleep/ \
	     ${sysconfdir} \
          "
FILES_${PN} += "${libdir}/*.so"
FILES_${PN}-dbg += "${libdir}/.debug"
INSANE_SKIP_${PN} = "ldflags"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "1"
INSANE_SKIP_${PN} = "${ERROR_QA} ${WARN_QA}"

