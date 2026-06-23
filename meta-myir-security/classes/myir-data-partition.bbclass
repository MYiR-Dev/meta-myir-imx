# myir-data-partition.bbclass
# Plain data partition for MYIR i.MX95 dm-verity images
#
# Adds a non-encrypted data partition (typically /data) to the WIC image
# so applications have persistent writable storage outside the dm-verity
# protected rootfs.
#
#
# Usage:
#   Add to conf/local.conf alongside myir-dmverity:
#     INHERIT += "myir-data-partition"
#
#   To use data partition WITHOUT encryption, also remove or comment out:
#     # INHERIT += "myir-encrypted"
#
# Chain of trust (with data partition):
#   AHAB(boot container) -> FIT verified boot(kernel+initramfs) -> dm-verity(rootfs)
#                                                            -> /data (plain ext4)
#
DISTROOVERRIDES .= ":myir-data-partition"

# --------------------------------------------------------------------------
# Data partition filesystem type
# Supported: ext2, ext3, ext4
# --------------------------------------------------------------------------
MYIR_DATA_PARTITION_TYPE ?= "ext4"

# --------------------------------------------------------------------------
# Data partition label (used in fstab: LABEL=DATA)
# --------------------------------------------------------------------------
MYIR_DATA_PARTITION_LABEL ?= "DATA"

# --------------------------------------------------------------------------
# Data partition mount point
# --------------------------------------------------------------------------
MYIR_DATA_PARTITION_MOUNTPOINT ?= "/data"

# --------------------------------------------------------------------------
# Data partition mount flags
# --------------------------------------------------------------------------
MYIR_DATA_PARTITION_MOUNT_FLAGS ?= "rw,nosuid,nodev,noatime,errors=remount-ro"

# --------------------------------------------------------------------------
# Data partition automount:
#   "-1": do not modify fstab (manual mount only)
#    "0": add fstab entry with 'noauto' option
#    "1": add fstab entry with 'auto' option (default)
# --------------------------------------------------------------------------
MYIR_DATA_PARTITION_AUTOMOUNT ?= "1"

# --------------------------------------------------------------------------
# Data partition size in MiB
# WIC requires explicit --size for ext4 partitions without a source plugin.
# --------------------------------------------------------------------------
MYIR_DATA_PARTITION_SIZE ?= "2048"

# --------------------------------------------------------------------------
# WIC file selection when data partition is active
# Uses the 4-partition variant with /data
# --------------------------------------------------------------------------
WKS_FILE:myir-data-partition = "myd-jmx95-15x15-lpddr5-data.wks.in"
