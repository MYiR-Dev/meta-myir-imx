#!/bin/sh
PART=0
EMMC_NODE=/dev/mmcblk${PART}

UBOOT_FILE=/root/mfgimage/imx-boot
KERNEL_DTB_DIR=/root/mfgimage/kernel_dtb
ROOTFS_FILE_EXT4=/root/mfgimage/rootfs-full.ext4

MYD_NAME="myd-lmx91"
FAC_NAME="imx91evk"
# MYS_NAME="mys-8mmx"
# MYD_JX8MP_NAME="myd-jx8mp"

HOSTNAME=`cat /etc/hostname`

if [ x"$HOSTNAME" == x"$MYD_NAME" ];then
  led1=cpu
  led2=91x:led1
  led3=91x:led2
elif [ x"$HOSTNAME" == x"$MYS_NAME" ];then
  led1=user
  led2=cpu
elif [ x"$HOSTNAME" == x"$MYD_JX8MP_NAME" ];then
	no_led=1  
	echo "no led!"
fi

LED_PID=-1
time=1

ECHO_TTY="/dev/ttyLP0"

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
	echo heartbeat > /sys/class/leds/91x\:led1/trigger                        
        echo heartbeat > /sys/class/leds/91x\:led2/trigger                        

	while [ 1 ]
	do
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
	echo 1 > /sys/class/leds/${led2}/brightness

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

	# 闪烁
	echo none > /sys/class/leds/91x\:led1/trigger
	echo 1 > /sys/class/leds/91x\:led1/brightness
	echo none > /sys/class/leds/91x\:led2/trigger
	echo 1 > /sys/class/leds/91x\:led2/brightness

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
unmount(){
	umount /dev/mmcblk0p1
    umount /dev/mmcblk0p2
	echo "********    "unmount ok "  ***********" >> ${ECHO_TTY}
    echo "***********************************************" >> ${ECHO_TTY} 
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
    echo 0 > /sys/block/mmcblk${PART}boot0/force_ro
    # clear env 
    dd if=${UBOOT_FILE} of=/dev/mmcblk${PART}boot0 
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
    # start_time=`date +%s`
    mkfs.ext4  /dev/mmcblk${PART}p2 <<EOF
y
EOF
    dd if=${ROOTFS_FILE_EXT4} of=/dev/mmcblk${PART}p2 bs=1M
    cmd_check $? "burn root faild"
    sync
    # end_time=`date +%s`
    # echo rootfs time:$(($end_time - $start_time))
}

reszie2fs_mmc(){
    umount /dev/mmcblk0p1
    umount /dev/mmcblk0p2
    sleep 2
    fsck.ext4 -f -y /dev/mmcblk0p2 <<EOF
EOF
sync
sleep 2
    resize2fs /dev/mmcblk${PART}p2
    cmd_check $? "reszie2fs mmc faild"
    sync
}

check_rootfs(){
    mkdir -p /mnt/mmcblk${PART}p2
    mount /dev/mmcblk${PART}p2 /mnt/mmcblk${PART}p2
    rootfs_hostname=`cat /mnt/mmcblk${PART}p2/etc/hostname`
    echo_fun "rootfs_hostname:$rootfs_hostname"

    if [ x"$rootfs_hostname" != x"$MYD_NAME" ];then
       echo_fun "not equal"
       reboot
    else
       echo_fun "equal"
    fi
}


flag=$1
if [[ X${flag} = X"plan" ]];then
plan="{\"step\":\"firmware\",\"PN\":\"xxx\",\"SN\":\"xxx\",\"CN\":\"xxx\",\"plan\":{\"num\":\"4\",\"modules\":{\"bootloader\":\"0\",\"kernel\":\"0\",\"rootfs\":\"0\"}}}"
echo ">>>[${#plan}]${plan}"
exit 1
fi

burn_start_ing &
LED_PID=$!
#sleep 1
unmount
echo_fun "start format mmc "
mksdcard ${EMMC_NODE}
echo_fun "start burn dtb and kernel "
burn_kernel_dtb
echo_fun "start burn rootfs "
burn_rootfs_ext4
echo_fun "start burn uboot "
burn_bootloader
echo $'>>>[100]{\"step\":\"firmware\",\"result\":{\"bootloader\":\"0\",\"kernel\":\"0\",\"rootfs\":\"0\"}}\r\n'
reszie2fs_mmc
check_rootfs
enable_bootpart
burn_succeed

if [ x"$HOSTNAME" == x"$MYS_NAME" ];then
  reboot
fi



