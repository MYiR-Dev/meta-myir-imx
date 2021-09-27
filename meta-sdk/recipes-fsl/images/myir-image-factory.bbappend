ROOTFS_POSTPROCESS_COMMAND_append_mx8 = "install_upgrade_info; "



install_upgrade_info() {



		if [ -f ${IMAGE_ROOTFS}${systemd_system_unitdir}/fac-burn-emmc.service ];then
			echo " " > ${IMAGE_ROOTFS}${systemd_system_unitdir}/fac-burn-emmc.service
		fi

		# Add no user longin 
    if [ -f  ${IMAGE_ROOTFS}${systemd_system_unitdir}/serial-getty@.service ]; then
        sed -i '/ExecStart/s/$/ -a root/g' ${IMAGE_ROOTFS}${systemd_system_unitdir}/serial-getty@.service
    fi


}
