# linux-dm-verity.inc
# DM-Verity Kernel Configuration for MYIR i.MX95 Platforms
#

SRC_URI:append = " \
    file://dm-verity.cfg \
"

DELTA_KERNEL_DEFCONFIG:append = " \
    dm-verity.cfg \
"
