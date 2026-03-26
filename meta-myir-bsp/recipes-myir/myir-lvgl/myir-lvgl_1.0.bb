DESCRIPTION = "MEasyLVGL GUI Library"
LICENSE = "CLOSED"

SRC_URI = "gitsm://github.com/MYiR-Dev/MEasyLVGL.git;protocol=https;branch=lf-6.12.y-myd-lmx9x-11x11"
SRCREV = "95ddc7da6a83eebe90ece565d307a59bd5f55f81"

S = "${WORKDIR}/git"

inherit cmake

EXTRA_OECMAKE += " \
    -DCMAKE_BUILD_TYPE=Release \
"


do_install() {

    install -d ${D}${bindir}
    install -m 0755 ${B}/myir_lvgl ${D}${bindir}/myir_lvgl


    install -d ${D}${datadir}/myir/lv_demos


    if [ -d ${S}/lv_demos/src/high_res/slides ]; then
        cp -r ${S}/lv_demos/src/high_res/slides ${D}${datadir}/myir/lv_demos/
    fi


    if [ -d ${S}/lv_demos/src/high_res/assets ]; then
        cp -r ${S}/lv_demos/src/high_res/assets ${D}${datadir}/myir/lv_demos/
    fi
}


FILES:${PN} += " \
    ${bindir}/myir_lvgl \
    ${datadir}/myir/lv_demos \
"