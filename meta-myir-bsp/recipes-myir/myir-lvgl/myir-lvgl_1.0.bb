DESCRIPTION = "MEasyLVGL GUI Library"
LICENSE = "CLOSED"

SRC_URI = "gitsm://github.com/MYiR-Dev/MEasyLVGL.git;protocol=https;branch=release_v9.3"
SRCREV = "c8a7754b26c8df76c8e16eeb15411d5bf00dffe5"

S = "${WORKDIR}/git"

inherit cmake pkgconfig

# LVGL v9.5 build dependencies (based on lv_conf.h enabled backends):
#   CONFIG_LV_USE_WAYLAND=1     -> wayland, wayland-protocols, libxkbcommon, wayland-native
#   CONFIG_LV_USE_LINUX_DRM=1    -> libdrm
#   CONFIG_LV_USE_EVDEV=1        -> libevdev
#   CONFIG_LV_USE_LINUX_FBDEV=1  -> (no extra deps)
#   LV_BUILD_SET_CONFIG_OPTS=ON -> python3-pcpp-native (preprocess lv_conf_internal.h)
DEPENDS += " \
    wayland \
    wayland-native \
    wayland-protocols \
    libxkbcommon \
    libdrm \
    libevdev \
    python3-pcpp-native \
"

EXTRA_OECMAKE += " \
    -DCMAKE_BUILD_TYPE=Release \
"


do_install() {

    install -d ${D}${bindir}
    # CMakeLists.txt sets EXECUTABLE_OUTPUT_PATH to ${CMAKE_BINARY_DIR}/bin
    install -m 0755 ${B}/bin/myir_lvgl ${D}${bindir}/myir_lvgl


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
