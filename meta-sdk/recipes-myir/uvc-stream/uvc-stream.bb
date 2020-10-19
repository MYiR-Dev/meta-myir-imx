# MYIR - 2020   Alex .
DESCRIPTION = "Extra files for MYiR"
LICENSE = "LGPLv2"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = " glibc jpeg "
SECTION = "libs"
LICENSE = "MIT"


SRCREV = "ae7736cbff338d2b6d8568378aa347ac71ef89f7"
MYIREXAMPLES_BRANCH ?= "master"
MYIREXAMPLES_SRC ?= "git://github.com/Alex-Hu2020/uvc_stream.git;protocol=https" 

SRC_URI = "${MYIREXAMPLES_SRC};branch=${MYIREXAMPLES_BRANCH} \
"

S = "${WORKDIR}/git"

do_compile () {
   make
}

#
do_install () {
   install -d ${D}/${bindir}/

   install -m 755 ${S}/uvc_stream ${D}/${bindir}/
}

FILES_${PN} = " \
            ${bindir} \
            "

INSANE_SKIP_${PN}-dev = "ldflags"
INSANE_SKIP_${PN} = "${ERROR_QA} ${WARN_QA}"
