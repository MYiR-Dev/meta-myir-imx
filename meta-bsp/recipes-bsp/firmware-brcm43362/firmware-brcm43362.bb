SUMMARY = "brcm43362 firmware"
LICENSE = "GPLv2"
PV = "0.1"
LIC_FILES_CHKSUM = "file://LICENCE;md5=309cc7bace8769cfabdd34577f654f8e"

SRC_URI = " \
    file://brcmfmac43362-sdio.txt \
    file://brcmfmac43362-sdio.bin \
    file://LICENCE \
"

S = "${WORKDIR}"

do_install (){
    install -d ${D}${base_libdir}/firmware/brcm
    cp -rfv brcmfmac43362-sdio.txt ${D}${base_libdir}/firmware/brcm/
    cp -rfv brcmfmac43362-sdio.bin ${D}${base_libdir}/firmware/brcm/
}


FILES_${PN} = "${base_libdir}/firmware/brcm \
"
