# no-fit.inc — Empty stub when FIT signature is not required
#
# This file is included by u-boot-imx_%.bbappend instead of
# u-boot-fit-signature.inc when:
#   - MYIR_FIT_ENABLE != 1, OR
#   - The machine is not mx6ull-generic-bsp (e.g. mx9-generic-bsp)
#
# The real u-boot-fit-signature.inc adds:
#   - fit-signature.cfg (CONFIG_FIT_SIGNATURE=RSA)
#   - fit-boot-6ull.cfg (CONFIG_BOOTCOMMAND="run mmcfboot")
#   - u-boot-fit-signature-nxp.inc (concat_dtb hooks)
#
# This empty file exists solely to make the conditional include
# in u-boot-imx_%.bbappend syntactically valid.
