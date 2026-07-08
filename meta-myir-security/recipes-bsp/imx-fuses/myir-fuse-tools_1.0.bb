SUMMARY = "MYIR i.MX Secure Boot Fuse Tools (AHAB + HAB)"
DESCRIPTION = "Key generation and fuse burning tools for i.MX9 AHAB and i.MX6/7 HABv4 secure boot"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://gen_keys.sh \
    file://gen_fuse_cmds.sh \
    file://myir-hab-create-fuse-cmds.sh \
    file://imx6ull-template.fuse \
"

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

do_install() {
    install -d ${D}${bindir}

    # AHAB tools (i.MX9)
    install -m 0755 ${UNPACKDIR}/gen_keys.sh ${D}${bindir}/myir-gen-ahab-keys
    install -m 0755 ${UNPACKDIR}/gen_fuse_cmds.sh ${D}${bindir}/myir-gen-fuse-cmds

    # HABv4 tools (i.MX6/7)
    install -m 0755 ${UNPACKDIR}/myir-hab-create-fuse-cmds.sh ${D}${bindir}/myir-create-fuse-cmds

    # HAB fuse template
    install -d ${D}${datadir}/imx-fuses
    install -m 0644 ${UNPACKDIR}/imx6ull-template.fuse ${D}${datadir}/imx-fuses/
}

# myir-hab-create-fuse-cmds.sh calls hexdump (from util-linux)
DEPENDS += "util-linux-native"

PROVIDES += "imx-fuses"
BBCLASSEXTEND = "native nativesdk"
