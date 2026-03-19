FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

SRC_URI += "file://0001-units-systemd-udevd-Set-PrivateMounts-to-no.patch"

PACKAGECONFIG:append = " sysvinit"

do_install:append () {

    # Add special touchscreen rules
    if [ -e  ${D}${sysconfdir}/udev/rules.d/touchscreen.rules ]; then
        cat <<EOF >>${D}${sysconfdir}/udev/rules.d/touchscreen.rules
SUBSYSTEM=="input", KERNEL=="event[0-9]*", ENV{ID_INPUT_TOUCHSCREEN}=="1", SYMLINK+="input/touchscreen0"
EOF
    fi
}