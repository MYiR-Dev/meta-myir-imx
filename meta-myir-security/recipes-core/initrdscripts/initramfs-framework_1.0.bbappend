# initramfs-framework_1.0.bbappend
# MYIR enhanced dm-verity overlay module
#
# When MYIR_DM_VERITY_OVERLAY is enabled, this bbappend adds the
# enhanced dmverity-overlay module to the initramfs-framework.
# When overlay is disabled, the upstream dmverity module is used
# instead (via meta-security's bbappend).
#
# Using MYIR_DM_VERITY_OVERLAY directly (not DISTROOVERRIDES)
# ensures reliable detection since the variable is set globally
# by myir-dmverity.bbclass via INHERIT.

#require ${@bb.utils.contains('MYIR_DM_VERITY_OVERLAY', '1', 'initramfs-framework-myir-dm.inc', '', d)}
include ${@bb.utils.contains('MYIR_DM_VERITY_OVERLAY', '1', 'initramfs-framework-myir-dm.inc', '', d)}

