# u-boot-fit-signature.inc
# U-Boot FIT signature verification support for i.MX6ULL HABv4 secure boot.
#
# This file is conditionally included by u-boot-imx_%.bbappend when
# MYIR_FIT_ENABLE=1 AND the machine is mx6ull-generic-bsp.
#
# It enables the CONFIG_FIT_SIGNATURE feature in U-Boot, which allows
# U-Boot to verify the kernel fitImage RSA signature at boot time.
#
# Guard: all additions are scoped to mx6ull-generic-bsp + MYIR_FIT_ENABLE=1
# to ensure zero impact on i.MX95 (mx9-generic-bsp) builds.

# FIT signature verification config fragment (CONFIG_FIT_SIGNATURE=y)
# Generic FIT configs only, no machine-specific BOOTCOMMAND.
SRC_URI:append:mx6ull-generic-bsp = " ${@bb.utils.contains("MYIR_FIT_ENABLE", "1", " file://fit-signature.cfg", "", d)}"

# 6ULL-specific fitImage boot command (CONFIG_BOOTCOMMAND="run mmcfboot")
# Separated from fit-signature.cfg to avoid any conflict with i.MX95 builds.
# SKIP when MYIR_HAB_TEE_MODE=fit: hab-tee-fit-boot.cfg provides its own BOOTCOMMAND
SRC_URI:append:mx6ull-generic-bsp = " ${@bb.utils.contains("MYIR_HAB_TEE_MODE", "fit", "", bb.utils.contains("MYIR_FIT_ENABLE", "1", " file://fit-boot-6ull.cfg", "", d), d)}"
# NXP-specific concat_dtb hooks for u-boot.imx format
# Safe require: only loaded when mx6ull-generic-bsp + MYIR_FIT_ENABLE=1
include ${@bb.utils.contains("MYIR_FIT_ENABLE", "1", "u-boot-fit-signature-nxp.inc", "no-fit-nxp.inc", d) if "mx6ull-generic-bsp" in d.getVar("OVERRIDES").split(":") else "no-fit-nxp.inc"}
