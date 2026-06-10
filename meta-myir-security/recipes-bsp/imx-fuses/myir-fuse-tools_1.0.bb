SUMMARY = "MYIR i.MX95 Secure Boot Fuse Tools"
DESCRIPTION = "Key generation and fuse burning tools for i.MX95 AHAB secure boot"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://gen_keys.sh file://gen_fuse_cmds.sh"

# Using UNPACKDIR for Scarthgap+ compatibility
S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/gen_keys.sh ${D}${bindir}/myir-gen-ahab-keys
    install -m 0755 ${UNPACKDIR}/gen_fuse_cmds.sh ${D}${bindir}/myir-gen-fuse-cmds
}

# These are host tools - build for native only
BBCLASSEXTEND = "native nativesdk"
