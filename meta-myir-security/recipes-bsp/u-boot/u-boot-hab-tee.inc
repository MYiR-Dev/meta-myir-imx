# u-boot-hab-tee.inc
# U-Boot HAB+TEE boot config fragment include for i.MX6ULL
#
# This file is conditionally included by u-boot-imx_%.bbappend when
# MYIR_HAB_TEE_MODE is set AND the machine is mx6ull-generic-bsp.
#
# It adds the appropriate BOOTCOMMAND config fragment based on the mode:
#   MYIR_HAB_TEE_MODE=nonfit → hab-tee-nonfit-boot.cfg (zImage+IVT+TEE)
#   MYIR_HAB_TEE_MODE=fit    → hab-tee-fit-boot.cfg   (fitImage+TEE, future)
#
# Guard: scoped to mx6ull-generic-bsp to ensure zero impact on
# i.MX95 (mx9-generic-bsp) and i.MX93 builds.

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Non-FIT HAB+TEE boot command (Scheme 1)
SRC_URI:append:mx6ull-generic-bsp = " \
    ${@bb.utils.contains('MYIR_HAB_TEE_MODE', 'nonfit', \
        'file://hab-tee-nonfit-boot.cfg', '', d)} \
"

# FIT HAB+TEE boot command (Scheme 2) — future
SRC_URI:append:mx6ull-generic-bsp = " \
    ${@bb.utils.contains('MYIR_HAB_TEE_MODE', 'fit', \
        'file://hab-tee-fit-boot.cfg', '', d)} \
"
