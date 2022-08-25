#!/bin/sh

UBOOT_FILE=/home/root/mfgimage/imx-boot
KERNEL_DTB_DIR=/home/root/mfgimage/kernel_dtb
ROOTFS_FILE_UBI=/home/root/mfgimage/rootfs-core.ext4

MYS_6ULL_NAME="mys-6ull"
MYD_NAME="myd-imx8mm"
MYS_NAME="mys-8mmx"
MYD_JX8MP_NAME="myd-jx8mp"

HOSTNAME=`cat /etc/hostname`
if [ x"$HOSTNAME" == x"$MYS_6ULL_NAME" ];then
    PART=1
    EMMC_NODE=/dev/mmcblk${PART}
    led1=cpu
    part_uboot=0
    part_env=1
    part_kernel=2
    part_dtb=3
    part_rootfs=4
elif [ x"$HOSTNAME" == x"$MYD_NAME" ];then
    led1=cpu
    led2=user2
    led3=user1
elif [ x"$HOSTNAME" == x"$MYS_NAME" ];then
  led1=user
  led2=cpu
elif [ x"$HOSTNAME" == x"$MYD_JX8MP_NAME" ];then
	no_led=1  
	echo "no led!"
fi

LED_PID=-1
time=0.2

ECHO_TTY="/dev/ttymxc1"

burn_start_ing(){


	if [[ ${no_led} -eq 1 ]];then
		exit 0;
	fi

	echo "***********************************************" >> ${ECHO_TTY} 
	echo "*************    SYSTEM UPDATE    *************" >> ${ECHO_TTY} 
	echo "***********************************************" >> ${ECHO_TTY} 
	echo "***********************************************" >> ${ECHO_TTY} 
    echo "*************   Update starting   *************" >> ${ECHO_TTY}  
    echo "***********************************************" >> ${ECHO_TTY} 
    echo "                                               " >> ${ECHO_TTY} 
    echo "                                               " >> ${ECHO_TTY} 
    echo "                                               " >> ${ECHO_TTY} 
    echo "                                               " >> ${ECHO_TTY} 

	#核心板上的绿灯闪烁则烧写中
	echo 0 > /sys/class/leds/${led1}/brightness
	echo 0 > /sys/class/leds/${led2}/brightness
    echo 0 > /sys/class/leds/${led3}/brightness

	while [ 1 ]
	do
		echo 1 > /sys/class/leds/${led1}/brightness
		sleep $time
		echo 0 > /sys/class/leds/${led1}/brightness
		sleep $time
        echo "*************   Updating   *************" >> ${ECHO_TTY} 
	done
}

burn_faild(){
	echo $'>>>[100]{\"step\":\"firmware\",\"result\":{\"bootloader\":\"2\",\"data\":\"2\",\"kernel\":\"2\",\"rootfs\":\"2\"}}\r\n'
	if [[ ${no_led} -eq 1 ]];then
		exit 0;
	fi

    kill $LED_PID

	# 熄灭
	echo 0 > /sys/class/leds/${led1}/brightness

    echo "Update faild..."   >> ${ECHO_TTY} 
    echo "Update faild..."   >> ${ECHO_TTY} 
    echo "Update faild..."   >> ${ECHO_TTY} 
}

burn_succeed(){
  echo $'>>>[100]{\"step\":\"firmware\",\"result\":{\"bootloader\":\"0\",\"data\":\"0\",\"kernel\":\"0\",\"rootfs\":\"0\"}}\r\n'
  if [[ ${no_led} -eq 1 ]];then
		return 0;
	fi
    
    kill $LED_PID

	# 常亮
	echo 1 > /sys/class/leds/${led1}/brightness

	echo "***********************************************" >> ${ECHO_TTY} 
	echo "********    SYSTEM UPDATE  SUCCEED  ***********" >> ${ECHO_TTY} 
    echo "********    SYSTEM UPDATE  SUCCEED  ***********" >> ${ECHO_TTY} 
    echo "********    SYSTEM UPDATE  SUCCEED  ***********" >> ${ECHO_TTY} 
	echo "***********************************************" >> ${ECHO_TTY} 
    echo "***********************************************" >> ${ECHO_TTY} 
    echo "                                               " >> ${ECHO_TTY} 

}

echo_fun(){
	echo "***********************************************" >> ${ECHO_TTY} 
	echo "********    "$1 "  ***********" >> ${ECHO_TTY}
    echo "***********************************************" >> ${ECHO_TTY} 
}

cmd_check()
{
	if [ $1 -ne 0 ];then
		echo "$2 failed!"   >> ${ECHO_TTY}
        echo "$2 failed!"   >> ${ECHO_TTY}
        echo "$2 failed!"   >> ${ECHO_TTY}
		burn_faild 
        exit -1
	fi
}

mksdcard(){
    #partition size in 10M
    BOOT_ROM_SIZE=10
    KERNEL_DTB_SIZE=100

    if [   $# -lt 1 ];then
	echo format node not exist
        exit 1
    else
	echo exist
    fi
    node=$1
    echo $node

    dd if=/dev/zero of=${node} bs=1k count=8192

    
    
sfdisk --force ${node} <<EOF
    ${BOOT_ROM_SIZE}M,${KERNEL_DTB_SIZE}M,0c
    $(($KERNEL_DTB_SIZE + 10))M,,83
EOF
    while [ 1 ]
    do
	if [ -b ${node}p2 ];then
		break
	else
		sleep 0.5
		echo ${node}p2 not exist
	fi
    done
}

enable_bootpart(){
    mmc bootpart enable 1 1 /dev/mmcblk${PART}
}

burn_bootloader(){
    #echo 0 > /sys/block/mmcblk${PART}boot0/force_ro
    # clear env 
    dd if=/dev/zero of=/dev/mtd${part_uboot} bs=1M count=5
    flash_erase /dev/mtd${part_uboot} 0 0 && kobs-ng init -x -v ${UBOOT_FILE}
    cmd_check $? "burn uboot faild"
    sleep 1


    #echo 1 > /sys/block/mmcblk${PART}boot0/force_ro
}

burn_kernel_dtb(){
    flash_erase /dev/mtd${part_kernel} 0 0 && nandwrite -p /dev/mtd${part_kernel} -p ${KERNEL_DTB_DIR}/zImage
    sleep 1
    flash_erase /dev/mtd${part_dtb} 0 0 && nandwrite -p /dev/mtd${part_dtb} -p ${KERNEL_DTB_DIR}/mys-6ull-14x14-gpmi-weim.dtb
    cmd_check $? "burn kernel dtb faild"
    sync
}

burn_rootfs_ubi(){
    flash_erase /dev/mtd${part_rootfs} 0 0
    if [ $? -ne 0 ]
    then
        echo "erase /dev/mtd${part_rootfs} fail"
        burn_faild
        exit
    fi
    nandwrite -q /dev/mtd${part_rootfs} ${ROOTFS_FILE_EXT4}
            ubiattach -m ${part_rootfs}

    cmd_check $? "burn root faild"
    sync
}

reszie2fs_mmc(){
    resize2fs /dev/mmcblk${PART}p2
    cmd_check $? "reszie2fs mmc faild"
    sync
}

check_rootfs(){
    mkdir -p /mnt/mmcblk${PART}p2
    mount /dev/mmcblk${PART}p2 /mnt/mmcblk${PART}p2
    rootfs_hostname=`cat /mnt/mmcblk${PART}p2/etc/hostname`
    echo_fun "rootfs_hostname:$rootfs_hostname"

    if [ x"$rootfs_hostname" != x"$HOSTNAME" ];then
       echo_fun "not equal"
       reboot
    else
       echo_fun "equal"
    fi
}

burn_start_ing &
LED_PID=$!
#sleep 1
echo_fun "start format mmc "
mksdcard ${EMMC_NODE}
echo_fun "start burn dtb and kernel "
burn_kernel_dtb
echo_fun "start burn rootfs "
burn_rootfs_ext4
echo_fun "start burn uboot "
burn_bootloader
reszie2fs_mmc
check_rootfs
enable_bootpart
burn_succeed

if [ x"$HOSTNAME" == x"$MYS_NAME" ];then
  reboot
fi



