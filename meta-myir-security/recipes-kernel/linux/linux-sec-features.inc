# linux-sec-features.inc
# Modular Security Feature Include for MYIR i.MX95 Kernel
#

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# dm-verity support (rootfs integrity)
include ${@'linux-dm-verity.inc' if 'myir-dmverity' in d.getVar('OVERRIDES').split(':') else 'no-dm-verity.inc'}

# dm-crypt support (data partition encryption)
include ${@'linux-dm-crypt.inc' if 'myir-encrypted' in d.getVar('OVERRIDES').split(':') else 'no-dm-crypt.inc'}

# OP-TEE RPMB-FS support (secure storage via eMMC RPMB partition)
include ${@oe.utils.conditional('MYIR_OPTEE_STORAGE', 'rpmb', 'linux-optee.inc', 'no-optee.inc', d)}
