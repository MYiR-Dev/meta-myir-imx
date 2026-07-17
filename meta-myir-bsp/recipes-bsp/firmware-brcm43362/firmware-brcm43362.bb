SUMMARY = "brcm43362 firmware"
LICENSE = "GPL-2.0-only"
PV = "0.1"
LIC_FILES_CHKSUM = "file://LICENCE;md5=309cc7bace8769cfabdd34577f654f8e"

SRC_URI = " \
    file://brcmfmac43362-sdio.bin;subdir=${BP} \
    file://brcmfmac43362-sdio.myir,myd-y6ulx.bin;subdir=${BP} \
    file://brcmfmac43362-sdio.txt;subdir=${BP} \
    file://brcmfmac43362-sdio.myir,myd-y6ulx.txt;subdir=${BP} \
    file://LICENCE;subdir=${BP} \
    file://brcmfmac.conf;subdir=${BP} \
"

S = "${WORKDIR}/${BP}"

do_install() {
    install -d ${D}${nonarch_base_libdir}/firmware/brcm

    install -m 644 ${S}/brcmfmac43362-sdio.bin ${D}${nonarch_base_libdir}/firmware/brcm/
    install -m 644 ${S}/brcmfmac43362-sdio.myir,myd-y6ulx.bin ${D}${nonarch_base_libdir}/firmware/brcm/
    install -m 644 ${S}/brcmfmac43362-sdio.txt ${D}${nonarch_base_libdir}/firmware/brcm/
    install -m 644 ${S}/brcmfmac43362-sdio.myir,myd-y6ulx.txt ${D}${nonarch_base_libdir}/firmware/brcm/

    install -d ${D}${sysconfdir}/modprobe.d
    install -m 644 ${S}/brcmfmac.conf ${D}${sysconfdir}/modprobe.d/
}

FILES:${PN} = " \
    ${nonarch_base_libdir}/firmware/brcm \
    ${sysconfdir}/modprobe.d/brcmfmac.conf \
"