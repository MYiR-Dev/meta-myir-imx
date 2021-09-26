ROOTFS_POSTPROCESS_COMMAND_append_mx8 = "install_upgrade_info; "



install_upgrade_info() {



		if [ -f ${IMAGE_ROOTFS}${systemd_system_unitdir}/fac-burn-emmc.service ];then
			echo " " > ${IMAGE_ROOTFS}${systemd_system_unitdir}/fac-burn-emmc.service
		fi

		


}
