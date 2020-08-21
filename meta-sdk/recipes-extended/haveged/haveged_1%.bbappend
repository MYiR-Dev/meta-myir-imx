do_install_append() {
    # The exit status is 143 when the service is stopped
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        sed -i '/ExecStart/a SuccessExitStatus=143' ${D}${systemd_system_unitdir}/haveged.service
        sed -i '/ExecStart/s/$/ -d 32/g' ${D}${systemd_system_unitdir}/haveged.service
    fi
}
