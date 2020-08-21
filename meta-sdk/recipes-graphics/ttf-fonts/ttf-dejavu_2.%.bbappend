# Fix up the fonts to the right location
# Install the ttf files into /usr/lib/fonts directory

PATH_TTF_FONTS="${libdir}/fonts"
do_install_append() {
    if [ ! -d ${D}/${PATH_TTF_FONTS} ]; then
        mkdir -p ${D}/${PATH_TTF_FONTS}
        cp -d ${S}/* ${D}/${PATH_TTF_FONTS}
        chown -R root:root ${D}/${PATH_TTF_FONTS}
    fi
}

FILES_${PN}-sans            += "${PATH_TTF_FONTS}/DejaVuSans.ttf ${PATH_TTF_FONTS}/DejaVuSans-*.ttf"
FILES_${PN}-sans-mono       += "${PATH_TTF_FONTS}/DejaVuSansMono*.ttf"
FILES_${PN}-sans-condensed  += "${PATH_TTF_FONTS}/DejaVuSansCondensed*.ttf"
FILES_${PN}-serif           += "${PATH_TTF_FONTS}/DejaVuSerif.ttf ${PATH_TTF_FONTS}/DejaVuSerif-*.ttf"
FILES_${PN}-serif-condensed += "${PATH_TTF_FONTS}/DejaVuSerifCondensed*.ttf"
FILES_${PN}-mathtexgyre     += "${PATH_TTF_FONTS}/DejaVuMathTeXGyre.ttf"


