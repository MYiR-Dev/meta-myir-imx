SUMMARY = "CST signing tools and keys for i.MX AHAB"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${THISDIR}/files/licenses/GPL-2;md5=54859035e4a74627c5fc90dd17a62132"

inherit deploy

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    file://crts-key.tar.gz \
    file://licenses/GPL-2;subdir=${BP} \
    file://csf_boot_image.txt \
    file://csf_linux_img.txt \
    file://csf_linux_hdmi_img.txt \
    file://csf_linux_lvds_img.txt \
    file://csf_linux_rgb_img.txt \
    file://csf_uboot_atf.txt \
    file://Release_Notes.txt \
    file://Software_Content_Register_CST.txt \
"

S = "${WORKDIR}/crts-key"

do_compile[noexec] = "1"
do_install[noexec] = "1"

do_deploy() {
    install -d ${DEPLOYDIR}/cst-signing

    cp -r ${S}/keys ${DEPLOYDIR}/cst-signing/
    cp -r ${S}/crts ${DEPLOYDIR}/cst-signing/
    cp -r ${S}/linux64 ${DEPLOYDIR}/cst-signing/

    for f in ${THISDIR}/files/*.txt; do
        install -m 0644 "$f" ${DEPLOYDIR}/cst-signing/
    done
}

addtask deploy after do_unpack before do_build