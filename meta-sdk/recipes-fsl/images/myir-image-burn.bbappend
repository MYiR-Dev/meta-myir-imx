ROOTFS_POSTPROCESS_COMMAND_append_mx8 = "install_upgrade_info; "



install_upgrade_info() {



		if [ -f ${IMAGE_ROOTFS}${systemd_system_unitdir}/check_upgrade.service ];then
			echo " " > ${IMAGE_ROOTFS}${systemd_system_unitdir}/check_upgrade.service
		fi

		if [ -f ${IMAGE_ROOTFS}/home/root/burn_emmc.sh ];then
			echo "reboot" >> ${IMAGE_ROOTFS}/home/root/burn_emmc.sh
		fi 


}
