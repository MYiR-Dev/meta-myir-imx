# Copyright 2020-2025 NXP

DESCRIPTION = "i.MX Verisilicon Software ISP"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://COPYING;md5=bc649096ad3928ec06a8713b8d787eac"
DEPENDS = "boost libdrm virtual/libg2d libtinyxml2 jsoncpp patchelf-native"

SRC_URI[sha256sum] = "b6e59b670a88a93295b3761cd785d87453bf7bb79a7ce2ea7f140579c888eac2"

SRC_URI:append = " \
    file://start_isp_ov13855.sh \
    file://run_ov13855.sh \
    file://OV13855_13M_10_2112x1568_linear.xml \
    file://OV13855_13M_10_4096x3072_linear.xml \
    file://OV13855_13M_10_4224x3136_linear.xml \
    file://sensor_dwe_ov13855_2112x1568_bypass.json \
    file://sensor_dwe_ov13855_4096x3072_bypass.json \
    file://sensor_dwe_ov13855_4224x3136_bypass.json \
"

IMX_SRCREV_ABBREV = "d9be886"

inherit fsl-eula2-unpack2 fsl-eula-recent cmake systemd use-imx-headers

PACKAGECONFIG = ""
# Note: building with tuningext fails with boost 1.87.
# (update to 1.87 with walnascar)
PACKAGECONFIG[tuningext] = "-DTUNINGEXT=1,-DTUNINGEXT=0"

# Build the sub-folder appshell
OECMAKE_SOURCEPATH = "${S}/appshell"

# Use make instead of ninja
OECMAKE_GENERATOR = "Unix Makefiles"

# Workaround for linking issues seen with gold linker
LDFLAGS:append = "${@bb.utils.contains('DISTRO_FEATURES', 'ld-is-gold', ' -fuse-ld=bfd ', '', d)}"

SYSTEMD_SERVICE:${PN} = "imx8-isp.service"

EXTRA_OECMAKE += " \
    -DSDKTARGETSYSROOT=${STAGING_DIR_HOST} \
    -DCMAKE_BUILD_TYPE=release \
    -DISP_VERSION=ISP8000NANO_V1802 \
    -DPLATFORM=ARM64 \
    -DQTLESS=1 \
    -DFULL_SRC_COMPILE=1 \
    -DWITH_DRM=1 \
    -DWITH_DWE=1 \
    -DSUBDEV_V4L2=1 \
    -DPARTITION_BUILD=0 \
    -D3A_SRC_BUILD=0 \
    -DIMX_G2D=ON \
    -Wno-dev \
"

# The NXP package has no OV13855 userspace sensor plug-in.  Its OS08A20
# plug-in is an implementation of the common VVSENSOR ioctl ABI, so generate
# an OV13855-specific copy and give it the OV13855 chip/driver identity.  The
# Install separate RAW10 IQ files below instead of shipping the copied OS08A20
# calibration data.  The 2112 file is the hardware-validated default, 4096 is
# the validated ISP crop for the native full sensor mode, and 4224 is retained
# as a diagnostic full-frame profile that exceeds the i.MX8MP ISP limits.
do_configure:prepend() {
    rm -rf ${S}/units/isi/drv/OV13855
    cp -R ${S}/units/isi/drv/OS08a20 ${S}/units/isi/drv/OV13855

    mv ${S}/units/isi/drv/OV13855/source/OS08a20.c \
       ${S}/units/isi/drv/OV13855/source/OV13855.c
    mv ${S}/units/isi/drv/OV13855/calib/OS08a20/OS08a20_8M_10_1080p_linear.xml \
       ${S}/units/isi/drv/OV13855/calib/OS08a20/OV13855_13M_10_2112x1568_linear.xml
    rm -f ${S}/units/isi/drv/OV13855/calib/OS08a20/OS08a20_*.xml
    rm -f ${S}/units/isi/drv/OV13855/*.cfg

    sed -i \
        -e 's/OS08A20/OV13855/g' \
        -e 's/OS08a20/OV13855/g' \
        -e 's/os08a20/ov13855/g' \
        ${S}/units/isi/drv/OV13855/CMakeLists.txt \
        ${S}/units/isi/drv/OV13855/source/OV13855.c \
        ${S}/units/isi/drv/OV13855/calib/OS08a20/OV13855_13M_10_2112x1568_linear.xml
    sed -i \
        -e 's/0x530841/0x00d855/g' \
        -e 's/0x2770/0x00d855/g' \
        ${S}/units/isi/drv/OV13855/source/OV13855.c
    # The upstream CMake file has OS08a20 in both mutually exclusive
    # GENERATE_PARTITION_BUILD branches.  Add OV13855 beside each occurrence
    # so either build mode produces the sensor plug-in and calibration file.
    sed -i '/add_subdirectory( drv\/OV13855 )/d' \
        ${S}/units/isi/CMakeLists.txt
    sed -i \
        '/add_subdirectory( drv\/OS08a20 )/a add_subdirectory( drv/OV13855 )' \
        ${S}/units/isi/CMakeLists.txt

    install -m 0644 ${UNPACKDIR}/OV13855_13M_10_2112x1568_linear.xml \
        ${S}/units/isi/drv/OV13855/calib/OS08a20/OV13855_13M_10_2112x1568_linear.xml
    install -m 0644 ${UNPACKDIR}/OV13855_13M_10_4096x3072_linear.xml \
        ${S}/units/isi/drv/OV13855/calib/OS08a20/OV13855_13M_10_4096x3072_linear.xml
    install -m 0644 ${UNPACKDIR}/OV13855_13M_10_4224x3136_linear.xml \
        ${S}/units/isi/drv/OV13855/calib/OS08a20/OV13855_13M_10_4224x3136_linear.xml
}

do_install() {
    # The Makefile unconditionally installs tuningext even if it is not built
    if ${@bb.utils.contains('PACKAGECONFIG','tuningext','false','true',d)}; then
        touch ${B}/generated/release/bin/tuningext
    fi

    oe_runmake -f ${S}/Makefile install INSTALL_DIR=${D} SOURCE_DIR=${S}

    if ${@bb.utils.contains('PACKAGECONFIG','tuningext','false','true',d)}; then
        rm ${D}/opt/imx8-isp/bin/tuningext
    fi

    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${systemd_system_unitdir}
        install -m 0644 ${S}/imx/imx8-isp.service ${D}${systemd_system_unitdir}
    fi

    mv ${D}/opt/imx8-isp/bin/start_isp.sh \
       ${D}/opt/imx8-isp/bin/start_isp_nxp.sh
    install -m 0755 ${UNPACKDIR}/start_isp_ov13855.sh \
        ${D}/opt/imx8-isp/bin/start_isp.sh
    install -m 0755 ${UNPACKDIR}/run_ov13855.sh \
        ${D}/opt/imx8-isp/bin/run_ov13855.sh
    install -d ${D}/opt/imx8-isp/bin/dewarp_config
    install -m 0644 ${UNPACKDIR}/sensor_dwe_ov13855_2112x1568_bypass.json \
        ${D}/opt/imx8-isp/bin/dewarp_config/sensor_dwe_ov13855_2112x1568_bypass.json
    install -m 0644 ${UNPACKDIR}/sensor_dwe_ov13855_4096x3072_bypass.json \
        ${D}/opt/imx8-isp/bin/dewarp_config/sensor_dwe_ov13855_4096x3072_bypass.json
    install -m 0644 ${UNPACKDIR}/sensor_dwe_ov13855_4224x3136_bypass.json \
        ${D}/opt/imx8-isp/bin/dewarp_config/sensor_dwe_ov13855_4224x3136_bypass.json

    # appshell may copy its prebuilt unversioned OS08A20 library over the
    # CMake-generated symlink on incremental builds.  Keep both sensor
    # libraries in the normal versioned-library layout expected below.
    ln -sfn libos08a20.so.1 ${D}${libdir}/libos08a20.so
    ln -sfn libov13855.so.1 ${D}${libdir}/libov13855.so
}

# The build contains a mix of versioned and unversioned libraries, so
# the default packaging configuration needs some modification so that
# unversioned .so libraries go to the main package and versioned .so
# symlinks go to -dev.
FILES_SOLIBSDEV = ""
FILES:${PN} += "/opt ${libdir}/lib*${SOLIBSDEV}"
FILES:${PN}-dev += "${FILES_SOLIBS_VERSIONED}"
FILES_SOLIBS_VERSIONED = " \
    ${libdir}/libcppnetlib-client-connections.so \
    ${libdir}/libcppnetlib-server-parsers.so \
    ${libdir}/libcppnetlib-uri.so \
    ${libdir}/libos08a20.so \
    ${libdir}/libov13855.so \
"

INSANE_SKIP:${PN} = "already-stripped"

RDEPENDS:${PN} = "libdrm"
RDEPENDS:${PN}:append:myd-js8mpq = " kernel-module-ov13855"

COMPATIBLE_MACHINE = "(mx8mp-nxp-bsp)"
