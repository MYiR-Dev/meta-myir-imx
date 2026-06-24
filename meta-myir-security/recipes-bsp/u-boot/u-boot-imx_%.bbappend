# Secure boot config fragments for MYIR i.MX95
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# AHAB boot support (i.MX95 only)
SRC_URI:append:mx9-generic-bsp = " \
   ${@bb.utils.contains('MYIR_AHAB_ENABLE', '1', \
        'file://mx9-generic-bsp/u-boot-hab.cfg', '', d)} \
"

# fitImage boot + FIT signature verification for i.MX95
SRC_URI:append = " \
    ${@bb.utils.contains("ENABLE_FITIMAGE_SIGN", "1", \
        "file://fitimage-boot.cfg", "", d)} \
"

# Secure boot combined config
SRC_URI:append = " \
    ${@bb.utils.contains('MYIR_AHAB_ENABLE', '1', \
        'file://u-boot-secure-boot.cfg', '', d)} \
"

# FIT signature verification
#SRC_URI:append = " \
#    ${@bb.utils.contains('MYIR_AHAB_ENABLE', '1', \
#        'file://fit-signature.cfg', '', d)} \
#"

# Hardening (command whitelist, bootm/CLI/bootargs protection)
SRC_URI:append = " \
    ${@bb.utils.contains('MYIR_AHAB_ENABLE', '1', \
        'file://u-boot-harden.cfg', '', d)} \
"

# Disable legacy image format when secure boot is enabled
SRC_URI:append = " \
    ${@bb.utils.contains('MYIR_AHAB_ENABLE', '1', \
        'file://disable-bootmeths.cfg', '', d)} \
"
#UBOOT_CONFIG_FRAGMENT:append = "${@bb.utils.contains('DISTRO_FEATURES', 'sec_boot', ' u-boot-hab.cfg', '', d)}"
#UBOOT_CONFIG_FRAGMENT:append = "${@bb.utils.contains('DISTRO_FEATURES', 'sec_boot', ' u-boot-secure-boot.cfg', '', d)}"
#UBOOT_CONFIG_FRAGMENT:append = "${@bb.utils.contains('DISTRO_FEATURES', 'sec_boot', ' fitimage-boot.cfg', '', d)}"
#UBOOT_CONFIG_FRAGMENT:append = "${@bb.utils.contains('DISTRO_FEATURES', 'sec_boot', ' disable-bootmeths.cfg', '', d)}"
#UBOOT_CONFIG_FRAGMENT:append = "${@bb.utils.contains('UBOOT_SIGN_ENABLE', '1', ' file://fit-signature.cfg', '', d)}"

