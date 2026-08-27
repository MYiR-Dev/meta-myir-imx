SUMMARY = "NXP CAAM black key and blob provisioning tool for MYD-JS8MPQ"
DESCRIPTION = "Builds caam-keygen for the MYD-JS8MPQ tagged-key dm-crypt flow."

LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=8636bd68fc00cc6a3809b7b58b45f982"

DEPENDS = "openssl"

SRC_URI = " \
    git://github.com/nxp-imx/keyctl_caam.git;protocol=https;nobranch=1 \
"
SRCREV = "8dba6d3cac24b5a6c8daaaf1eda70fa18d488139"

PV = "1.0+git${SRCPV}"
S = "${WORKDIR}/git"

# The standard i.MX security package installs the same caam-keygen binary.
# This board-specific build changes KEYBLOB_LOCATION for the transient
# dm-crypt provisioning directory, so it is the encrypted image's drop-in
# replacement rather than a co-installable second copy.
RPROVIDES:${PN} += "keyctl-caam"
RREPLACES:${PN} += "keyctl-caam"
RCONFLICTS:${PN} += "keyctl-caam"

CAAM_KEYBLOB_LOCATION = "/run/myd-js8mpq-caam-dmcrypt/"

EXTRA_OEMAKE = " \
    CC='${CC}' \
    OPENSSL_PATH='${STAGING_DIR_TARGET}${prefix}' \
    KEYBLOB_LOCATION='${CAAM_KEYBLOB_LOCATION}' \
    LDFLAGS='${LDFLAGS} -lcrypto' \
"

do_compile() {
    oe_runmake
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/caam-keygen ${D}${bindir}/caam-keygen
}

COMPATIBLE_MACHINE = "^myd-js8mpq$"
