# linux-sec-features.inc
# Modular Security Feature Include for MYIR Kernel
#

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# dm-verity support (rootfs integrity)
include ${@'linux-dm-verity.inc' if 'myir-dmverity' in d.getVar('OVERRIDES').split(':') else 'no-dm-verity.inc'}

# dm-crypt support (data partition encryption)
include ${@'linux-dm-crypt.inc' if 'myir-encrypted' in d.getVar('OVERRIDES').split(':') else 'no-dm-crypt.inc'}

# OP-TEE RPMB-FS support (secure storage via eMMC RPMB partition)
include ${@oe.utils.conditional('MYIR_OPTEE_STORAGE', 'rpmb', 'linux-optee.inc', 'no-optee.inc', d)}

# ==========================================================================
# HAB+TEE Mode Auto-Configuration
#
# MYIR_HAB_TEE_MODE controls which HABv4 + OP-TEE boot scheme is active:
#   - "nonfit" : zImage + IVT/CSF signing + OP-TEE  (Scheme 1)
#   - "fit"    : fitImage + HAB auth + OP-TEE        (Scheme 2)
#   - ""       : existing behavior (no HAB+TEE auto-config)
#
# When MYIR_HAB_TEE_MODE is set, the following variables are dynamically
# overridden to enforce the correct combination:
#
#   Mode          | MYIR_FIT_ENABLE | MYIR_KERNEL_HAB_SIGN
#   --------------|-----------------|-----------------------
#   nonfit        | 0               | 1   ← zImage with IVT+CSF
#   fit           | 1               | 0   ← fitImage with external HAB+internal TEE
#   (empty/other) | (user-set)      | (user-set) ← no override
#
# The python block enforces mutual exclusion. The bb.utils.contains()
# includes below then pull in the correct signing method.
# ==========================================================================
python __hab_tee_mode_config() {
    mode = d.getVar('MYIR_HAB_TEE_MODE')
    if not mode:
        return

    if mode == 'nonfit':
        # Scheme 1: zImage with IVT+CSF signing + OP-TEE
        if d.getVar('MYIR_FIT_ENABLE') == '1':
            bb.warn("MYIR_HAB_TEE_MODE=nonfit overrides MYIR_FIT_ENABLE: 1 -> 0")
        d.setVar('MYIR_FIT_ENABLE', '0')
        d.setVar('MYIR_KERNEL_HAB_SIGN', '1')
        bb.debug(1, 'HAB+TEE Mode: nonfit (FIT=off, HAB kernel=on)')

    elif mode == 'fit':
        # Scheme 2: fitImage with HAB auth + OP-TEE
        if d.getVar('MYIR_KERNEL_HAB_SIGN') == '1':
            bb.warn("MYIR_HAB_TEE_MODE=fit overrides MYIR_KERNEL_HAB_SIGN: 1 -> 0")
        d.setVar('MYIR_FIT_ENABLE', '1')
        d.setVar('MYIR_KERNEL_HAB_SIGN', '0')
        bb.debug(1, 'HAB+TEE Mode: fit (FIT=on, HAB kernel=off)')

    else:
        bb.warn("Unknown MYIR_HAB_TEE_MODE='%s', expected 'nonfit' or 'fit'" % mode)
        return

    # Ensure TEE kernel config fragments are loaded
    # linux-hab-tee.inc handles the SRC_URI additions for optee.cfg + tee.cfg
    # (with duplicate guard against linux-optee.inc for RPMB coexistence)
    bb.debug(1, 'HAB+TEE Mode: kernel TEE config loaded via linux-hab-tee.inc')
}
addhandler __hab_tee_mode_config
__hab_tee_mode_config[eventmask] = "bb.event.ConfigParsed"

# ==========================================================================
# Mutual exclusion: FIT Image vs HAB kernel (IVT+CSF) signing
#
# These two kernel signing methods are mutually exclusive — you must
# choose exactly one (or none). Both set to "1" is a configuration error.
#
# MYIR_HAB_TEE_MODE auto-config runs before this check (ConfigParsed
# event), so auto-overridden values are validated here.
# ==========================================================================
python () {
    fit = d.getVar('MYIR_FIT_ENABLE')
    hab_kernel = d.getVar('MYIR_KERNEL_HAB_SIGN')
    if fit == '1' and hab_kernel == '1':
        bb.fatal("MYIR_FIT_ENABLE=1 and MYIR_KERNEL_HAB_SIGN=1 are mutually exclusive.\n" +
                 "  - FIT Image signing:  set MYIR_FIT_ENABLE=1, MYIR_KERNEL_HAB_SIGN=0\n" +
                 "  - HAB kernel (IVT+CSF): set MYIR_FIT_ENABLE=0, MYIR_KERNEL_HAB_SIGN=1\n" +
                 "  - No kernel signing:  set both to 0\n" +
                 "  - Or use MYIR_HAB_TEE_MODE=nonfit|fit for auto-config")
}

# ==========================================================================
# Kernel OP-TEE support for HAB+TEE boot schemes
#
# Loads linux-hab-tee.inc when MYIR_HAB_TEE_MODE is set ('nonfit' or 'fit').
# This adds optee.cfg + tee.cfg kernel config fragments unconditionally.
#
# When MYIR_HAB_TEE_MODE is empty, a stub (no-optee.inc) is loaded instead.
#
# Coexistence with linux-optee.inc (RPMB):
#   - If both MYIR_HAB_TEE_MODE and MYIR_OPTEE_STORAGE=rpmb are active,
#     linux-hab-tee.inc detects this and skips its own SRC_URI additions
#     (the optee.cfg + tee.cfg are already added by linux-optee.inc).
#   - This prevents duplicate config fragment errors.
# ==========================================================================
include ${@oe.utils.conditional('MYIR_HAB_TEE_MODE', '', 'no-optee.inc', 'linux-hab-tee.inc', d)}

# ==========================================================================
# FIT Image signing for i.MX6ULL HABv4 secure boot
#
# Conditionally includes linux-fitimage.inc which forces the kernel to be
# built as a fitImage (instead of zImage) and configures FIT RSA signing
# parameters. This is NOT used by i.MX95 (AHAB uses kernel container).
#
# Controlled by MYIR_FIT_ENABLE (defaults to MYIR_HAB_ENABLE).
# Set MYIR_FIT_ENABLE = "0" to disable FIT signing while keeping HAB.
# ==========================================================================
include ${@bb.utils.contains("MYIR_FIT_ENABLE", "1", "linux-fitimage.inc", "no-fitimage.inc", d)}

# ==========================================================================
# HAB kernel signing (IVT+CSF method) for i.MX6ULL
#
# The NXP i.MX6 HAB User's Guide documents kernel authentication via
# the ROM HAB API: authenticate_image() verifies the kernel through an
# IVT (Image Vector Table) and CSF binary appended to the kernel image.
#
# This is an alternative to FIT Image signing. Use when you want the
# ROM (not U-Boot) to verify the kernel.
#
# Controlled by MYIR_KERNEL_HAB_SIGN. Default: disabled.
# ==========================================================================
include ${@bb.utils.contains("MYIR_KERNEL_HAB_SIGN", "1", "linux-hab-sign.inc", "no-hab-sign.inc", d)}

# ==========================================================================
# FIT + OP-TEE integration (Scheme 2 only)
#
# When MYIR_HAB_TEE_MODE=fit, injects OP-TEE as a loadable into the
# fitImage ITS. The TEE binary (tee.bin from optee-os) is added to the
# images section and each configuration gets loadables = "tee-1".
#
# linux-fit-tee.inc hooks into do_assemble_fitimage:append to modify
# the ITS after fitimage_assemble() generates it, then rebuilds the
# fitImage with the TEE embedded.
# ==========================================================================
include ${@bb.utils.contains("MYIR_HAB_TEE_MODE", "fit", "linux-fit-tee.inc", "", d)}
