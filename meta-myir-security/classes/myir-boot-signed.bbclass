# myir-boot-signed.bbclass
# Signed boot container (AHAB) WIC image — no dm-verity/dm-crypt
#
# This class is the minimal entry point for secure boot when you want
# the imx-boot container signed by AHAB but do NOT need rootfs
# integrity protection (dm-verity) or data encryption (dm-crypt).
#
# It selects a WKS layout where partition 1 uses imx-boot-signed
# (the AHAB-signed container produced by myir-kernel-container-sign)
# instead of the unsigned imx-boot.tagged.
#
# Usage:
#   Add to conf/local.conf:
#     INHERIT += "myir-boot-signed"
#
# Prerequisites (must be inherited separately):
#   - myir-ahab.bbclass                  (key generation)
#   - myir-kernel-container-sign.bbclass (AHAB signing, deploys imx-boot-signed)
#
# Typical local.conf for signed boot only:
#   INHERIT += "myir-ahab myir-kernel-container-sign myir-boot-signed"
#
# Reference:
#   - meta-freescale/wic/imx-imx-boot-bootpart.wks.in (base layout)
#   - myir-dmverity.bbclass (dm-verity variant, same DISTROOVERRIDES pattern)

# --------------------------------------------------------------------------
# Register override for conditional WKS_FILE selection
# --------------------------------------------------------------------------
DISTROOVERRIDES .= ":myir-boot-signed"

# --------------------------------------------------------------------------
# Select the WKS layout that uses imx-boot-signed in partition 1
# --------------------------------------------------------------------------
WKS_FILE:myir-boot-signed = "myd-jmx95-15x15-lpddr5-signed.wks.in"
