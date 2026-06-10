# Secure boot config fragments for MYIR i.MX95
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# AHAB boot support (i.MX95 only)
SRC_URI:append:mx9-generic-bsp = " \
    file://mx9-generic-bsp/u-boot-hab.cfg \
"

# Secure boot combined config
SRC_URI:append = " \
    ${@bb.utils.contains('MYIR_AHAB_ENABLE', '1', \
        'file://u-boot-secure-boot.cfg', '', d)} \
"

# FIT signature verification
SRC_URI:append = " \
    ${@bb.utils.contains('MYIR_AHAB_ENABLE', '1', \
        'file://fit-signature.cfg', '', d)} \
"

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
