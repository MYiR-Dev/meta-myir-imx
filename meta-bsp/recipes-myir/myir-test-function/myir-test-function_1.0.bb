SUMMARY = "UART and Watchdog test applications for MYIR boards"
DESCRIPTION = "A simple UART test program and a watchdog test program for testing serial communication (RS232/RS485) and watchdog functionality"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://uart_test.c \
           file://watchdog.c \
           file://Makefile"

S = "${WORKDIR}"

do_compile() {
    oe_runmake
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 uart_test ${D}${bindir}/uart_test
    install -m 0755 watchdog_test ${D}${bindir}/watchdog_test
}

FILES:${PN} = "${bindir}/uart_test ${bindir}/watchdog_test"
