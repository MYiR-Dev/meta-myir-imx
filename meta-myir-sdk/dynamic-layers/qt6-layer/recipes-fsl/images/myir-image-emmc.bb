# Copyright (C) 2015 Freescale Semiconductor
# Copyright 2017-2021 NXP
# Released under the MIT license (see COPYING.MIT for the terms)

require recipes-fsl/images/myir-image-multimedia.bb

inherit populate_sdk_qt6
# Override: meta-qt6 populate_sdk_qt6_base forces SDKIMAGE_FEATURES += staticdev-pkgs,
# but our PACKAGE_EXCLUDE prevents apt from installing Qt6 staticdev packages.
# This conflict causes "no installation candidate" errors during do_populate_sdk.
# Remove staticdev-pkgs since we do not ship Qt6 .a files in the SDK.
SDKIMAGE_FEATURES:remove = " staticdev-pkgs"

CONFLICT_DISTRO_FEATURES = "directfb"

# Strip packages not needed on target:
# - Remove staticdev (.a static libs, saves ~750 MB)
# - Remove qemu (full-system emulators, saves ~230 MB)
# PACKAGE_EXCLUDE works at package-manager level, blocking both direct
# installs and dependency-chain pulls (unlike IMAGE_INSTALL:remove)
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

IMAGE_INSTALL += " \
    curl \
    packagegroup-qt6-imx \
    qtvirtualkeyboard \
    qtimageformats \
    tzdata \
    ${IMAGE_INSTALL_OPENCV} \
    ${IMAGE_INSTALL_PARSEC} \
    ${IMAGE_INSTALL_PKCS11TOOL} \
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
