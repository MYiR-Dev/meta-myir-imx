#!/bin/sh
PART=2
EMMC_NODE=/dev/mmcblk${PART}

UBOOT_FILE=/home/root/mfgimage/imx-boot
KERNEL_DTB_DIR=/home/root/mfgimage/kernel_dtb
ROOTFS_FILE_EXT4=/home/root/mfgimage/rootfs-full.ext4

MYS_6ULL_NAME="mys-6ull"
MYD_NAME="myd-imx8mm"
MYS_NAME="mys-8mmx"
MYD_JX8MP_NAME="myd-jx8mp"

HOSTNAME=`cat /etc/hostname`
if [ x"$HOSTNAME" == x"$MYS_6ULL_NAME" ];then
    PART=1
    led1=cpu
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

    if [   $# -lt 1 ];then
	    echo format node not exist
        exit 1
    else
	    echo exist
    fi

    if [ ! -f /sys/block/mmcblk${PART}/size ];then
        echo sys/block/mmcblk${PART{}/size not exit
        exit 1
    else
	    echo exist
    fi


    #partition size in 10M
    BOOT_ROM_SIZE=10
    KERNEL_DTB_SIZE=100
    EMMC_SIZE=`cat /sys/block/mmcblk${PART}/size`
    EMMC_SIZE=$((${EMMC_SIZE} * 512 / 1024 / 1024))
    echo EMMC_SIZE ${EMMC_SIZE}
    HALF_SIZE=$(((${EMMC_SIZE}  - ${ROOT_ROM_SIZE} - ${KERNEL_DTB_SIZE} ) / 2))
    echo "half_size ${HALF_SIZE}"


    dd if=/dev/zero of=${node} bs=1k count=8192

    
    
sfdisk --force ${node} <<EOF
    ${BOOT_ROM_SIZE}M,${KERNEL_DTB_SIZE}M,0c
    $(($KERNEL_DTB_SIZE + ${BOOT_ROM_SIZE}))M,${HALF_SIZE}M,83
    $(($KERNEL_DTB_SIZE + ${BOOT_ROM_SIZE} + ${HALF_SIZE}))M,,83
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
    echo 0 > /sys/block/mmcblk${PART}boot0/force_ro
    # clear env 
    if [ x"$HOSTNAME" == x"$MYS_6ULL_NAME" ];then
        dd if=${UBOOT_FILE} of=/dev/mmcblk${PART}boot0 bs=1k seek=1
	elif [ x"$HOSTNAME" == x"$MYD_JX8MP_NAME" ];then
    	dd if=${UBOOT_FILE} of=/dev/mmcblk${PART}boot0 
    else
    	dd if=${UBOOT_FILE} of=/dev/mmcblk${PART}boot0 bs=1k seek=33
    fi
    cmd_check $? "burn uboot faild"
    sleep 1


    echo 1 > /sys/block/mmcblk${PART}boot0/force_ro
}

burn_kernel_dtb(){
    mkfs.vfat  /dev/mmcblk${PART}p1
    mkdir -p /mnt/mmcblk${PART}p1
    mount -t vfat /dev/mmcblk${PART}p1 /mnt/mmcblk${PART}p1
    cp ${KERNEL_DTB_DIR}/* /mnt/mmcblk${PART}p1
    cmd_check $? "burn kernel dtb faild"
    sync
}

burn_rootfs_ext4(){
    for index in 2 3
        do
        # start_time=`date +%s`
        mkfs.ext4  /dev/mmcblk${PART}p${index} <<EOF
        y
EOF
        dd if=${ROOTFS_FILE_EXT4} of=/dev/mmcblk${PART}p${index} bs=1M
        cmd_check $? "burn root faild"
        sync
    done
    # end_time=`date +%s`
    # echo rootfs time:$(($end_time - $start_time))
}

reszie2fs_mmc(){
    for index in 2 3
    do
        resize2fs /dev/mmcblk${PART}p${index}
        cmd_check $? "reszie2fs mmc faild"
        sync
    done
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



