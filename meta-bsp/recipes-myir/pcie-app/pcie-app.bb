DESCRIPTION = "pcie app"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRCREV = "66e752609cd35ac0e6dd98ed165720706bb1ec79"
SRC_URI = "git://github.com/Alex-Hu2020/pcie-driver.git;branch=pcie_app \
           "
S = "${WORKDIR}/git"

do_compile () {
      make
}

do_install () {
      install -d ${D}/usr/bin/
      install -m 755 ${S}/testutil ${D}/usr/bin/
}

FILES_${PN} = " \
	       /usr/bin/ \
             "

TARGET_CC_ARCH += "${LDFLAGS}"
INSANE_SKIP_${PN}-dev = "ldflags"
INSANE_SKIP_${PN} = "${ERROR_QA} ${WARN_QA}"
