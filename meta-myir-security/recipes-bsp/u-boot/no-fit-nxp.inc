# no-fit-nxp.inc — Empty stub when NXP concat_dtb hooks are not needed
#
# This file is included by u-boot-fit-signature.inc instead of
# u-boot-fit-signature-nxp.inc when:
#   - MYIR_FIT_ENABLE != 1, OR
#   - The machine is not mx6ull-generic-bsp
#
# The real u-boot-fit-signature-nxp.inc provides concat_dtb() hooks
# for the NXP u-boot.imx format.
#
# This empty file exists solely to make the conditional include
# syntactically valid.
