# MYIR - 2020   Alex .
DESCRIPTION = "Extra files for MYiR"
LICENSE = "LGPLv2"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "zlib glibc ncurses "
SECTION = "libs"
LICENSE = "MIT"


SRCREV = "a3f9ba961556816d29a454b22a1bec0ea5e2fb08"
MYIREXAMPLES_BRANCH ?= "myd-y6ulx"
MYIREXAMPLES_SRC ?= "git://github.com/MYiR-Dev/myir-linux-examples.git;protocol=https" 

SRC_URI = "${MYIREXAMPLES_SRC};branch=${MYIREXAMPLES_BRANCH} \
"

S = "${WORKDIR}/git"

do_compile () {
   make
}

#
do_install () {
   install -d ${D}/${bindir}/

   install -m 755 ${S}/can/can_send ${D}/${bindir}/
   install -m 755 ${S}/can/can_receive ${D}/${bindir}/

   install -m 755 ${S}/framebuffer/framebuffer_test ${D}/${bindir}/
   install -m 755 ${S}/gpio_led/gpio_led ${D}/${bindir}/
   install -m 755 ${S}/gpio_key/gpio_key ${D}/${bindir}/

   install -m 755 ${S}/uart/uart_test ${D}/${bindir}/
   install -m 755 ${S}/rs485/rs485_read ${D}/${bindir}/
   install -m 755 ${S}/rs485/rs485_write ${D}/${bindir}/
   install -m 755 ${S}/rs485/rs485_recv_send ${D}/${bindir}/
   install -m 755 ${S}/rtc/rtc_test ${D}/${bindir}/
   install -m 755 ${S}/network/arm_server ${D}/${bindir}/
   install -m 755 ${S}/network/arm_client ${D}/${bindir}/
   install -m 755 ${S}/watchdog/watchdog_test ${D}/${bindir}/
}

FILES_${PN} = " \
            ${bindir} \
            "

INSANE_SKIP_${PN}-dev = "ldflags"
INSANE_SKIP_${PN} = "${ERROR_QA} ${WARN_QA}"
