#!/bin/bash



flag=$1
if [[ X${flag} = X"plan" ]];then
plan="{\"step\":\"firmware\",\"PN\":\"xxx\",\"SN\":\"xxx\",\"CN\":\"xxx\",\"plan\":{\"num\":\"7\",\"modules\":{\"tfa\":\"0\", \"meta_data\":\"2000\",\"fip\":\"40000\",\"boot_rootfs\":\"40000\",\"vendor_rootfs\":\"40000\",\"rootfs\":\"40000\",\"user_rootfs\":\"40000\"}}}"
echo ">>>[${#plan}]${plan}"
exit 1
fi


imagedir=/home/root/ld25x_images
. ${imagedir}/Manifest




MMC_info=$(dmesg | grep "MMC")

MMCtest=$(echo "$MMC_info" | cut -d':' -f1 | awk '{print $3}')

MMCNUM=$(echo "$MMCtest" | awk -F'c' '{print $2}')


DRIVE=/dev/mmcblk${MMCNUM}





FSBLA_FILE=${imagedir}/${fsbla}
META_FILE=${imagedir}/${metadata}
FIP_FILE=${imagedir}/${fip}
BOOTFS_FILE=${imagedir}/${bootfs}
VENDORFS_FILE=${imagedir}/${vendorfs}
ROOTFS_FILE=${imagedir}/${rootfs}
USERFS_FILE=${imagedir}/${userfs}



#echo 405 > /sys/class/gpio/export
#echo out > /sys/class/gpio/PZ5/direction



echo $FSBLA_FILE
echo $META_FILE
echo $FIP_FILE
echo $BOOTFS_FILE
echo $VENDORFS_FILE
echo $ROOTFS_FILE
echo $USERFS_FILE



led()
{
	while true; do
	echo 1 > /sys/class/leds/blue:heartbeat/brightness
	echo 1 > /sys/class/leds/green:heartbeat/brightness
		sleep 1
	echo 0 > /sys/class/leds/blue:heartbeat/brightness 
	echo 0 > /sys/class/leds/green:heartbeat/brightness 
	echo "Updating..." > /dev/ttySTM0
    	sleep 1
	done
}

update_success()
{
	while true;do
		echo "Update complete..."  > /dev/ttySTM0
		sleep 2
		echo "Update complete..." > /dev/ttySTM0
		sleep 3
	done
}

update_fail()
{
	kill $LED_PID
	echo 0 > /sys/class/leds/blue:heartbeat/brightness 
	echo 0 > /sys/class/leds/green:heartbeat/brightness 

	while true;do
		echo "Update failed..." > /dev/ttySTM0
		sleep 2
		echo "Update failed..." > /dev/ttySTM0
		sleep 2
	done
}



cmd_check()
{
	if [ $1 -ne 0 ];then
		echo "$2 failed!"
		echo
		update_fail
	fi
}



check_file()
{
	if [ ! -s $1 ];then
		echo "invalid imagefile $1"
		echo
		update_fail
	fi
}


mkfs_emmc_all()                                
{                                          
	mkfs.ext4 ${DRIVE} <<EOF
	y
EOF
}              

fdisk_emmc(){
	/home/root/fdisk_emmc.sh
	cmd_check $? "Fdisk Emmc" 
}




mkfs_emmc()
{
	mkfs.ext4 ${DRIVE}p6 <<EOF
	y
EOF
	mkfs.ext4 ${DRIVE}p7 <<EOF
	y
EOF
	mkfs.ext4 ${DRIVE}p8 <<EOF
	y
EOF
	mkfs.ext4 ${DRIVE}p9 <<EOF
	y
EOF
}


erasing_emmc()
{
	# Erasing eMMC
	echo -e "\n== Destroying Master Boot Record (sector 0) =="
	sleep 1
	echo dd if=/dev/zero of=${DRIVE} bs=1024 count=1
	dd if=/dev/zero of=${DRIVE} bs=1024 count=1
	sync
}

burn_fsbla()
{
	echo 0 > /sys/block/mmcblk${MMCNUM}boot0/force_ro
	echo 0 > /sys/block/mmcblk${MMCNUM}boot1/force_ro
	sleep 1
	dd if=${FSBLA_FILE} of=/dev/mmcblk${MMCNUM}boot0 conv=fsync
	cmd_check $? "Update arm-trusted-firmware boot0 file"
	dd if=${FSBLA_FILE} of=/dev/mmcblk${MMCNUM}boot1 conv=fsync
	cmd_check $? "Update arm-trusted-firmware boot1 file"
	sleep 1
	echo 1 > /sys/block/mmcblk${MMCNUM}boot0/force_ro
	echo 1 > /sys/block/mmcblk${MMCNUM}boot1/force_ro
	sync
}


burn_metadata()
{
	dd if=${META_FILE} of=${DRIVE}p1 bs=1M conv=fsync
	cmd_check $? "Update metadatafile"
	sync
        dd if=${META_FILE} of=${DRIVE}p2 bs=1M conv=fsync
	cmd_check $? "Update metadatafile"
	sync
	sleep 1
	sync
}


burn_fip()
{
	dd if=${FIP_FILE} of=${DRIVE}p3 bs=1M conv=fsync
	cmd_check $? "Update u-boot file"
	sync
	sleep 1
}





enable_emmc()
{
	mmc bootpart enable 1 1 /dev/mmcblk${MMCNUM}
	cmd_check $? "Enable boot partion 1 to boot"
}



burn_boot_rootfs()
{
#	/home/root//flash.sh
	dd if=${BOOTFS_FILE} of=${DRIVE}p6 iflag=nocache oflag=nocache bs=1M
#	sudo dd if=stm32mp2_image/st-image-bootfs-openstlinux-weston-stm32mp2.ext4 of=/dev/mmcblk1p6 iflag=nocache oflag=nocache bs=1M
	cmd_check $? "Update boot rootfs"
	sync
}


burn_vendor_rootfs()
{
	dd if=${VENDORFS_FILE} of=${DRIVE}p7 bs=1M conv=fsync
	cmd_check $? "Update vendor rootfs"
	sync
}

burn_rootfs()
{
	dd if=${ROOTFS_FILE} of=${DRIVE}p8 bs=1M conv=fsync
	cmd_check $? "Update rootfs"
	sync
}

burn_user_rootfs()
{
	dd if=${USERFS_FILE} of=${DRIVE}p9 bs=1M conv=fsync
	cmd_check $? "Update user rootfs"
	sync
}



resize2fs_emmc()
{
	e2fsck -f  ${DRIVE}p6 <<EOF
	y
EOF
	resize2fs   ${DRIVE}p6 <<EOF
	y
EOF

	e2fsck -f  ${DRIVE}p7 <<EOF
	y
EOF
	resize2fs   ${DRIVE}p7 <<EOF
	y
EOF

	e2fsck -f  ${DRIVE}p8 <<EOF
	y
EOF
	resize2fs   ${DRIVE}p8 <<EOF
	y
EOF

	e2fsck -f  ${DRIVE}p9 <<EOF
	y
EOF
	resize2fs   ${DRIVE}p9 <<EOF
	y
EOF

  	sync
}



led &
LED_PID=$!


echo "---------------------------start mkfs_emmc_all ---------------------------"   > /dev/ttySTM0
mkfs_emmc_all
echo "---------------------------end mkfs_emmc_all ---------------------------" > /dev/ttySTM0

echo "---------------------------start fidsk_emmc ---------------------------" > /dev/ttySTM0
fdisk_emmc
echo "---------------------------end fidsk_emmc ---------------------------" > /dev/ttySTM0

sleep 1

echo "---------------------------start burn arm-trusted-firmware ---------------------------" > /dev/ttySTM0
burn_fsbla
echo "---------------------------end burn arm-trusted-firmware ---------------------------" > /dev/ttySTM0
echo "\n"




echo "---------------------------start burn meta_data ---------------------------" > /dev/ttySTM0
burn_metadata
echo "---------------------------end burn meta_data ---------------------------" > /dev/ttySTM0
echo "\n"




echo "---------------------------start burn fip ---------------------------" > /dev/ttySTM0
burn_fip
echo "---------------------------end burn fip ---------------------------" > /dev/ttySTM0
echo "\n"

sleep 2
enable_emmc
sleep 1


echo "---------------------------start boot rootfs ---------------------------" > /dev/ttySTM0

burn_boot_rootfs
i=1
while [ $i -lt 8 ]; do
	mount ${DRIVE}p6 /mnt
	if [ $? -eq 0 ]; then
    		echo "Mount boot_rootfs successfully"
    		umount /mnt
		break
	else
    		echo "Mount command failed"
    		burn_boot_rootfs
	fi
	if [ $i -eq 7]; then
		echo ">>>[${#boot_rootfs_failed}]${boot_rootfs_failed}"
	fi
	((i++))
done




echo "---------------------------end boot rootfs---------------------------" > /dev/ttySTM0
echo "\n"






echo "---------------------------start vendor rootfs ---------------------------" > /dev/ttySTM0
burn_vendor_rootfs
echo "---------------------------end vendor rootfs---------------------------" > /dev/ttySTM0
echo "\n"





echo "---------------------------start rootfs ---------------------------" > /dev/ttySTM0
burn_rootfs
echo "---------------------------end rootfs---------------------------" > /dev/ttySTM0
echo "\n"




echo "---------------------------start user rootfs ---------------------------" > /dev/ttySTM0
burn_user_rootfs
echo "---------------------------end user rootfs---------------------------" > /dev/ttySTM0
echo "\n"




resize2fs_emmc

echo "---------------------------update success---------------------------" > /dev/ttySTM0
echo "---------------------------update success---------------------------" > /dev/ttySTM0
echo "---------------------------update success---------------------------" > /dev/ttySTM0


kill $LED_PID
echo 1 > /sys/class/leds/blue:heartbeat/brightness 
echo 1 > /sys/class/leds/green:heartbeat/brightness 
