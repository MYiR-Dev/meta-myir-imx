# Remove ntp — systemd-timesyncd handles time sync on this board
RDEPENDS:${PN}:remove = "ntp"
