# linux-dm-crypt.inc
# DM-Crypt Kernel Configuration for MYIR i.MX95 Platforms
#

SRC_URI:append = "\
    file://dm-crypt.cfg \
    file://trusted-keys.cfg \
    file://${MYIR_ENC_KEY_BACKEND}.cfg \
"

DELTA_KERNEL_DEFCONFIG:append = " \
    dm-crypt.cfg \
    trusted-keys.cfg \
    ${MYIR_ENC_KEY_BACKEND}.cfg \
"
