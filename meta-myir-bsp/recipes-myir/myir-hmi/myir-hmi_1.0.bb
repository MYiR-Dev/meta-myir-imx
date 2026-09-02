DESCRIPTION = "MYiR HMI Qt6 Demo Application"
SUMMARY = "MEasy_HMI - Qt6/QML HMI demo for i.MX9 Platforms"
LICENSE = "CLOSED"

SRC_URI = "gitsm://github.com/MYiR-Dev/mxapp.git;protocol=https;branch=MXAPP2-QT6-IMX9X \
           file://msyh.ttc \
           file://myir.mp4 \
           file://myir.png \
           file://myir.bmp \
           file://myir.jpg \
"
SRCREV = "3da3aa1f8b108019ccacdcaecaae403de18173a5"

S = "${UNPACKDIR}/git"

DEPENDS = "\
    qtbase \
    qtdeclarative \
    qtdeclarative-native \
    qtmultimedia \
    qttools-native \
    qtvirtualkeyboard \
"

inherit qt6-cmake


EXTRA_OECMAKE = "-DCMAKE_BUILD_TYPE=Release"
EXTRA_OECMAKE:append:mx93-nxp-bsp = " -DENABLE_SOFTWARE_QUICK_BACKEND=ON"
EXTRA_OECMAKE:append:mx95-nxp-bsp = " -DENABLE_PLAYER=ON"
EXTRA_OECMAKE:append:myd-js8mpq = " -DENABLE_PLAYER=ON"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/mxapp2 ${D}${bindir}

    install -d ${D}${datadir}/fonts/ttf
    install -m 0644 ${UNPACKDIR}/msyh.ttc ${D}${datadir}/fonts/ttf/

    install -d ${D}${datadir}/myir/Video
    install -m 0644 ${UNPACKDIR}/myir.mp4 ${D}${datadir}/myir/Video/

    install -d ${D}${datadir}/myir/Capture
    install -m 0644 ${UNPACKDIR}/myir.png ${D}${datadir}/myir/Capture/
    install -m 0644 ${UNPACKDIR}/myir.bmp ${D}${datadir}/myir/Capture/
    install -m 0644 ${UNPACKDIR}/myir.jpg ${D}${datadir}/myir/Capture/
}

FILES:${PN} += "\
    ${bindir}/mxapp2 \
    ${datadir}/fonts/ttf/msyh.ttc \
    ${datadir}/myir/Video/myir.mp4 \
    ${datadir}/myir/Capture/myir.png \
    ${datadir}/myir/Capture/myir.bmp \
    ${datadir}/myir/Capture/myir.jpg \
"

COMPATIBLE_MACHINE = "(mx8mp-nxp-bsp|mx93-nxp-bsp|mx95-nxp-bsp)"
