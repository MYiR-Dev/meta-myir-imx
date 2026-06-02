FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

SRC_URI += "\
    file://0001-units-systemd-udevd-Set-PrivateMounts-to-no.patch \
    file://debug-console.conf \
"

PACKAGECONFIG:append = " sysvinit"

WATCHDOG_RUNTIME_SEC ??= "30"

do_install:append () {

		# Enable watchdog
    if [ -f "${D}${sysconfdir}/systemd/system.conf" ]; then
        sed -i -e 's/#RuntimeWatchdogSec=off/RuntimeWatchdogSec=${WATCHDOG_RUNTIME_SEC}/' \
                "${D}${sysconfdir}/systemd/system.conf" || bbwarn "Failed to set RuntimeWatchdogSec"
    else
        bbwarn "system.conf not found in do_install, RuntimeWatchdogSec not set"
    fi

    # Add special touchscreen rules
    if [ -e  ${D}${sysconfdir}/udev/rules.d/touchscreen.rules ]; then
        cat <<EOF >>${D}${sysconfdir}/udev/rules.d/touchscreen.rules
SUBSYSTEM=="input", KERNEL=="event[0-9]*", ENV{ID_INPUT_TOUCHSCREEN}=="1", SYMLINK+="input/touchscreen0"
EOF
    fi
    
    
		#This creates a drop-in config for timesyncd to set custom NTP servers
    if [ ! -f "${D}${sysconfdir}/systemd/timesyncd.conf" ]; then
        echo "# Custom NTP configuration" > "${D}${sysconfdir}/systemd/timesyncd.conf"
        echo "[Time]" >> "${D}${sysconfdir}/systemd/timesyncd.conf"
    fi

    if ! grep -q "^NTP=" "${D}${sysconfdir}/systemd/timesyncd.conf"; then
        echo "NTP=ntp.ntsc.ac.cn cn.ntp.org.cn" >> "${D}${sysconfdir}/systemd/timesyncd.conf"
    else
        sed -i 's/^NTP=.*/NTP=ntp.ntsc.ac.cn cn.ntp.org.cn/' "${D}${sysconfdir}/systemd/timesyncd.conf"
    fi

    chmod 0644 "${D}${sysconfdir}/systemd/timesyncd.conf"

    # Install serial-getty drop-in for dumb terminal (TERM=dumb, no reset)
    install -d ${D}${sysconfdir}/systemd/system/serial-getty@.service.d
    install -m 0644 ${UNPACKDIR}/debug-console.conf ${D}${sysconfdir}/systemd/system/serial-getty@.service.d/
}

FILES:${PN} += "${sysconfdir}/systemd/system/serial-getty@.service.d/debug-console.conf"