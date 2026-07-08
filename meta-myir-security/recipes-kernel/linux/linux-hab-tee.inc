# linux-hab-tee.inc
# Kernel OP-TEE configuration for HAB+TEE boot schemes (i.MX6ULL)
#
# Loaded when MYIR_HAB_TEE_MODE is set to 'nonfit' or 'fit'.
# Adds optee.cfg + tee.cfg unconditionally for kernel-level TEE support.
#
# Guard: skips SRC_URI additions if already handled by linux-optee.inc
# (RPMB mode), to avoid duplicate config fragment entries.
#
# Distinction from linux-optee.inc:
#   - linux-optee.inc: loaded when MYIR_OPTEE_STORAGE=rpmb, adds
#     optee.cfg + tee.cfg + rpmb.cfg
#   - linux-hab-tee.inc: loaded when MYIR_HAB_TEE_MODE is set, adds
#     optee.cfg + tee.cfg only (no RPMB dependency)
#
# Both can coexist: if MYIR_HAB_TEE_MODE=nonfit AND MYIR_OPTEE_STORAGE=rpmb,
# linux-optee.inc adds optee.cfg+tee.cfg+rpmb.cfg, and linux-hab-tee.inc
# skips its additions to avoid duplicates.

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

python __anonymous() {
    mode = d.getVar('MYIR_HAB_TEE_MODE')
    if not mode or mode not in ('nonfit', 'fit'):
        return

    # Skip if linux-optee.inc (RPMB mode) already added these
    optee_storage = d.getVar('MYIR_OPTEE_STORAGE')
    if optee_storage == 'rpmb':
        bb.debug(1, 'linux-hab-tee: skipping, already handled by linux-optee.inc (RPMB)')
        return

    # OP-TEE kernel driver support
    d.appendVar('SRC_URI', ' file://optee.cfg')
    d.appendVar('DELTA_KERNEL_DEFCONFIG', ' optee.cfg')

    # Trusted Keys via TEE
    d.appendVar('SRC_URI', ' file://tee.cfg')
    d.appendVar('DELTA_KERNEL_DEFCONFIG', ' tee.cfg')

    bb.debug(1, 'linux-hab-tee: optee.cfg + tee.cfg added for HAB_TEE_MODE=%s' % mode)
}
