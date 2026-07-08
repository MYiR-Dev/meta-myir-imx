# linux-fitimage.inc
# FIT Image signing configuration for i.MX6ULL HABv4 secure boot kernel.
#
# This file is conditionally included by linux-sec-features.inc when
# MYIR_FIT_ENABLE=1. It forces the kernel to be built as a fitImage
# (instead of zImage), enabling the chain of trust:
#
#   ROM (HABv4) -> U-Boot (HAB-signed) -> fitImage (FIT RSA-signed)
#                                              |
#                                              +-- kernel (Image.gz)
#                                              +-- dtb
#                                              +-- ramdisk
#
# MUTUALLY EXCLUSIVE with HAB kernel (IVT+CSF) signing.
# Set MYIR_KERNEL_HAB_SIGN=0 when using MYIR_FIT_ENABLE=1.
#
# Guard: all fitImage overrides are scoped to mx6ull-generic-bsp to
# ensure zero impact on i.MX95 (mx9-generic-bsp) builds.

# Belt-and-suspenders: fatal if both FIT and HAB kernel signing are enabled
python () {
    if d.getVar('MYIR_FIT_ENABLE') == '1' and d.getVar('MYIR_KERNEL_HAB_SIGN') == '1':
        bb.fatal("linux-fitimage.inc: MYIR_FIT_ENABLE=1 conflicts with MYIR_KERNEL_HAB_SIGN=1.\n" +
                 "  These are mutually exclusive kernel signing methods.")
}

# Force fitImage build when HABv4 is enabled
KERNEL_CLASSES:append:mx6ull-generic-bsp = " ${@bb.utils.contains("MYIR_FIT_ENABLE", "1", " kernel-fitimage", "", d)}"

KERNEL_IMAGETYPE:mx6ull-generic-bsp = "${@bb.utils.contains("MYIR_FIT_ENABLE", "1", "fitImage", "zImage", d)}"

# FIT hash and signature algorithm
FIT_HASH_ALG ?= "sha256"
FIT_SIGN_ALG ?= "rsa2048"

# Enable U-Boot FIT signature
UBOOT_SIGN_ENABLE = "1"
UBOOT_SIGN_KEYDIR ?= "${TOPDIR}/keys/fit"
UBOOT_SIGN_KEYNAME ?= "dev"
UBOOT_SIGN_IMG_KEYNAME ?= "dev2"
