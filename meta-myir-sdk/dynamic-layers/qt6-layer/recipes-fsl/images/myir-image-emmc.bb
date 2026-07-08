# Copyright (C) 2015 Freescale Semiconductor
# Copyright 2017-2021 NXP
# Released under the MIT license (see COPYING.MIT for the terms)

# This recipe is for mx93/mx95 machines only (Qt6-capable SOCs).
# mx6ull uses the non-qt6 variant at:
#   meta-myir-sdk/recipes-fsl/images/myir-image-emmc.bb
COMPATIBLE_MACHINE = "(mx93-nxp-bsp|mx95-nxp-bsp)"

require recipes-fsl/images/myir-image-multimedia.bb

inherit populate_sdk_qt6
# Override: meta-qt6 populate_sdk_qt6_base forces SDKIMAGE_FEATURES += staticdev-pkgs,
# but our PACKAGE_EXCLUDE prevents apt from installing Qt6 staticdev packages.
# This conflict causes "no installation candidate" errors during do_populate_sdk.
# Remove staticdev-pkgs since we do not ship Qt6 .a files in the SDK.
SDKIMAGE_FEATURES:remove = " staticdev-pkgs"

CONFLICT_DISTRO_FEATURES = "directfb"

# PACKAGE_EXCLUDE: works for rootfs AND SDK in DEB via apt Pin-Priority: -1.
# Strips Qt6 staticdev (.a) libs (~800 MB) and unused QEMU/xen (~230 MB).
PACKAGE_EXCLUDE = " \
    qtbase-staticdev \
    qtdeclarative-staticdev \
    qtlanguageserver-staticdev \
    qtquick3d-staticdev \
    qemu \
    qemu-common \
    qemu-system-i386 \
    xen-tools \
    ntp \
"

IMAGE_INSTALL_OPENCV              = ""
IMAGE_INSTALL_OPENCV:imxgpu       = "${IMAGE_INSTALL_OPENCV_PKGS}"
IMAGE_INSTALL_OPENCV:mx93-nxp-bsp = "${IMAGE_INSTALL_OPENCV_PKGS}"
IMAGE_INSTALL_OPENCV:mx943-nxp-bsp = "${IMAGE_INSTALL_OPENCV_PKGS}"
IMAGE_INSTALL_OPENCV_PKGS = " \
    opencv-apps \
    opencv-samples \
    python3-opencv"

IMAGE_INSTALL_PARSEC = " \
    packagegroup-security-tpm2 \
    packagegroup-security-parsec \
    swtpm \
    softhsm \
    os-release \
    ${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'optee-client optee-os', '', d)}"

IMAGE_INSTALL_PKCS11TOOL = ""
IMAGE_INSTALL_PKCS11TOOL:mx8-nxp-bsp = "opensc pkcs11-provider"
IMAGE_INSTALL_PKCS11TOOL:mx9-nxp-bsp = "opensc pkcs11-provider"

# Qt6-specific packages only for mx93/mx95 (guarded by OVERRIDES).
# curl/tzdata are now provided by myir-image-multimedia.bb (COMMON tier),
# so they are intentionally omitted here to avoid cross-recipe duplication.
QT6_IMAGE_INSTALL = " \
    packagegroup-qt6-imx \
    qtvirtualkeyboard \
    qtimageformats \
    ${IMAGE_INSTALL_OPENCV} \
    ${IMAGE_INSTALL_PARSEC} \
    ${IMAGE_INSTALL_PKCS11TOOL} \
"

IMAGE_INSTALL:append:mx93-nxp-bsp = " ${QT6_IMAGE_INSTALL}"
IMAGE_INSTALL:append:mx95-nxp-bsp = " ${QT6_IMAGE_INSTALL}"

export IMAGE_BASENAME = "myir-image-emmc"
