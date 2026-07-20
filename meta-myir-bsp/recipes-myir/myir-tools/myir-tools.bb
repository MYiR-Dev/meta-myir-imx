SUMMARY = "myir utils 2.0 - audio and camera test utilities"
DESCRIPTION = "myir audio/camera test scripts and sample media files"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${THISDIR}/files/${MACHINE}/licenses/GPL-2;md5=a3ac5472be79591e880a452856ca24d1"


FILESEXTRAPATHS:prepend := "${THISDIR}/files/${MACHINE}:"

SRC_URI = " \
    file://etc/myir_test/myir_audio_play;subdir=${BP} \
    file://etc/myir_test/myir_camera_capture;subdir=${BP} \
    file://etc/myir_test/myir_camera_preview;subdir=${BP} \
    file://etc/myir_test/myir_audio_arecord;subdir=${BP} \
    file://usr/share/myir/song.mp3;subdir=${BP} \
    file://usr/share/myir/song.wav;subdir=${BP} \
    file://licenses/GPL-2;subdir=${BP} \
"


S = "${WORKDIR}/${BP}"

do_install:mx6ull-nxp-bsp() {
    install -d ${D}${datadir}/myir/Music
    install -d ${D}/etc/myir_test

    install -m 0644 ${S}/etc/myir_test/myir_audio_arecord ${D}/etc/myir_test/
    install -m 0644 ${S}/usr/share/myir/song.wav ${D}${datadir}/myir/Music/
}

do_install:mx93-nxp-bsp() {
    install -d ${D}${datadir}/myir/Music
    install -d ${D}/etc/myir_test

    install -m 0755 ${S}/etc/myir_test/myir_audio_play ${D}/etc/myir_test/
    install -m 0755 ${S}/etc/myir_test/myir_camera_capture ${D}/etc/myir_test/
    install -m 0755 ${S}/etc/myir_test/myir_camera_preview ${D}/etc/myir_test/

    install -m 0644 ${S}/usr/share/myir/song.mp3 ${D}${datadir}/myir/Music/
    install -m 0644 ${S}/usr/share/myir/song.wav ${D}${datadir}/myir/Music/
}


do_install:mx95-nxp-bsp() {
    install -d ${D}${datadir}/myir/Music
    install -d ${D}/etc/myir_test

    install -m 0755 ${S}/etc/myir_test/myir_audio_play ${D}/etc/myir_test/

    install -m 0644 ${S}/usr/share/myir/song.mp3 ${D}${datadir}/myir/Music/
    install -m 0644 ${S}/usr/share/myir/song.wav ${D}${datadir}/myir/Music/
}


FILES:${PN} += " \
    ${datadir}/myir/Music/ \
    /etc/myir_test/ \
"
