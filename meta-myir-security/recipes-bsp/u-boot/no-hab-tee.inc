# no-hab-tee.inc — Empty stub when HAB+TEE is not required
#
# This file is included by u-boot-imx_%.bbappend instead of
# u-boot-hab-tee.inc when:
#   - MYIR_HAB_TEE_MODE is not set, OR
#   - The machine is not mx6ull-generic-bsp (e.g. mx9-generic-bsp)
#
# The real u-boot-hab-tee.inc adds BOOTCOMMAND config fragments
# (hab-tee-nonfit-boot.cfg or hab-tee-fit-boot.cfg) and OP-TEE
# build dependency (do_configure[depends]).
#
# This empty file exists solely to make the conditional include
# in u-boot-imx_%.bbappend syntactically valid.
