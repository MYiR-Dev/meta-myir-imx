FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

SRC_URI += "file://0001-units-systemd-udevd-Set-PrivateMounts-to-no.patch \
            file://0020-logind.conf-Set-HandlePowerKey-to-ignore.patch \
            file://89-unmanage.network"

PACKAGECONFIG[unmanaged-network] = ""

WATCHDOG_RUNTIME_SEC ??= "30"

do_install:append () {

    # Disable the assignment of the fixed network interface name
    install -d ${D}${sysconfdir}/systemd/network
    ln -s /dev/null ${D}${sysconfdir}/systemd/network/99-default.link

    # Configure the network as unmanaged
    if [ "${@bb.utils.filter('PACKAGECONFIG', 'unmanaged-network', d)}" ]; then
        install -Dm 0644 ${WORKDIR}/89-unmanage.network ${D}${sysconfdir}/systemd/network/
    fi

    # Add special touchscreen rules
    if [ -e  ${D}${sysconfdir}/udev/rules.d/touchscreen.rules ]; then
        cat <<EOF >>${D}${sysconfdir}/udev/rules.d/touchscreen.rules
# i.MX specific touchscreen rules
SUBSYSTEM=="input", KERNEL=="event[0-9]*", ENV{ID_INPUT_TOUCHSCREEN}=="1", SYMLINK+="input/touchscreen0"
EOF
    fi

    if [ -f "${D}${sysconfdir}/systemd/system.conf" ]; then
	sed -i -e 's/#RuntimeWatchdogSec=off/RuntimeWatchdogSec=${WATCHDOG_RUNTIME_SEC}/' \
		"${D}${sysconfdir}/systemd/system.conf" || bbwarn "Failed to set RuntimeWatchdogSec"
    else
	bbwarn "system.conf not found in do_install, RuntimeWatchdogSec not set"
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
}
