SUMMARY = "MYD-JS8MPQ CAAM tagged-key dm-crypt packages"
DESCRIPTION = "Board-scoped runtime package group for the encrypted data partition."

LICENSE = "MIT"

inherit packagegroup

PACKAGE_ARCH = "${MACHINE_ARCH}"

RDEPENDS:${PN} = " \
    myd-js8mpq-caam-dmcrypt \
    myd-js8mpq-caam-keygen \
"

COMPATIBLE_MACHINE = "^myd-js8mpq$"
