# Copyright 2018-2026 MYIR
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "MYIR i.MX6ULL EMMC image (non-Qt6, armv7a)"
LICENSE = "MIT"

# This recipe applies to i.MX6ULL machines (armv7a, no Qt6 support).
# For i.MX93/i.MX95 Qt6-enabled images, see:
#   dynamic-layers/qt6-layer/recipes-fsl/images/myir-image-emmc.bb
#
# As of 2026-06-29, myir-image-multimedia.bb handles machine-aware
# package selection via three tiers (COMMON / MX9 / MX6ULL).
# IMAGE_FEATURES already includes package-management (from multimedia.bb),
# so no additional override is needed here.
COMPATIBLE_MACHINE = "(mx6ull-nxp-bsp)"

# Remove Hailo NPU packages unconditionally injected by meta-hailo layer.conf.
# 6ul does not have Hailo hardware; these packages fail to compile due to
# cmake FetchContent network timeouts (libhailort, libgsthailo).
# 93/95 are unaffected — they use the separate qt6-layer variant.
IMAGE_INSTALL:remove = " packagegroup-hailo-tappas-dev-pkg"

require recipes-fsl/images/myir-image-multimedia.bb
SDKIMAGE_FEATURES:remove = " staticdev-pkgs"

OPTEE_TEST_6ULL          ?= ""
OPTEE_TEST_6ULL = "lvm2 optee-test optee-client python3-cryptography optee-examples openssl"

IMAGE_INSTALL_PARSEC = " \
    os-release \
    ${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'optee-client optee-os ${OPTEE_TEST_6ULL}', '', d)} \
"
CORE_IMAGE_EXTRA_INSTALL:append:mx6ull-nxp-bsp = " ${IMAGE_INSTALL_PARSEC}"
