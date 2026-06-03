SUMMARY = "Quectel QConnectManager"
DESCRIPTION = "Quectel connection manager and proxy tools"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI = "file://src"

S = "${WORKDIR}/src"

do_compile() {
    oe_runmake release \
        CC="${CC}" \
        CFLAGS="${CFLAGS} ${CPPFLAGS} -Wall -Wextra -O1" \
        LDFLAGS="${LDFLAGS} -lpthread -ldl -lrt"
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/quectel-CM ${D}${bindir}/quectel-CM
}

FILES:${PN} += " \
    ${bindir}/quectel-CM \
"
