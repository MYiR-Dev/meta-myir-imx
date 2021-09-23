SUMMARY = "quectel-CM file for Quectel EC20"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRCREV = "cab625effb8fe4f3ebf44599aa5071e70dc92cbb"
S_BRANCH ?= "master"
S_SRC ?= "git://github.com/coin-haha/quectel-cm.git;protocol=https"

S = "${WORKDIR}/git"

SRC_URI = "${S_SRC};branch=${S_BRANCH} \
"

do_compile (){
  make 
}

do_install () {
    install -d ${D}${bindir}

    install -m 0755 ${S}/quectel-CM ${D}${bindir}
}

FILES_${PN} += "${bindir}"

INSANE_SKIP_${PN}-dev = "ldflags"
INSANE_SKIP_${PN} = "${ERROR_QA} ${WARN_QA}"
