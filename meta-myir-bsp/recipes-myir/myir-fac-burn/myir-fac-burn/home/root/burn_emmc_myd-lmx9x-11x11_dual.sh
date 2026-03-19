#!/bin/sh
PART=0
EMMC_NODE=/dev/mmcblk${PART}

UBOOT_FILE=/root/mfgimage/imx-boot
KERNEL_DTB_DIR=/root/mfgimage/kernel_dtb
ROOTFS_FILE_EXT4=/root/mfgimage/rootfs-full.ext4

MYD_NAME="myd-lmx9x-11x11"


HOSTNAME=`cat /etc/hostname`

led1=93x:led1
led2=93x:led2



ECHO_TTY="/dev/ttyLP0"


burn_process()
{
        echo timer > /sys/class/leds/${led1}/trigger
        echo 200 >  /sys/class/leds/${led1}/delay_on
        echo 200 >  /sys/class/leds/${led1}/delay_off

        echo timer > /sys/class/leds/${led2}/trigger
        echo 200 >  /sys/class/leds/${led2}/delay_on
        echo 200 >  /sys/class/leds/${led2}/delay_off


}


burn_sucesss()
{
        echo timer > /sys/class/leds/${led1}/trigger
        echo 1 >  /sys/class/leds/${led1}/delay_on
        echo 0 >  /sys/class/leds/${led1}/delay_off
        
        echo timer > /sys/class/leds/${led2}/trigger
        echo 1 >  /sys/class/leds/${led2}/delay_on
        echo 0 >  /sys/class/leds/${led2}/delay_off

}
burn_fail()
{
        echo timer > /sys/class/leds/${led1}/trigger
        echo 0 >  /sys/class/leds/${led1}/delay_on
        echo 1 >  /sys/class/leds/${led1}/delay_off

        echo timer > /sys/class/leds/${led2}/trigger
        echo 0 >  /sys/class/leds/${led2}/delay_on
        echo 1 >  /sys/class/leds/${led2}/delay_off
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
		burn_fail 
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
    RESERVED_SIZE=50
    EMMC_SIZE=`cat /sys/block/mmcblk${PART}/size`
    EMMC_SIZE=$((${EMMC_SIZE} * 512 / 1024 / 1024))
    echo EMMC_SIZE ${EMMC_SIZE}
    AVAILABLE_SIZE=$((EMMC_SIZE - BOOT_ROM_SIZE - KERNEL_DTB_SIZE - RESERVED_SIZE))
    HALF_SIZE=$((AVAILABLE_SIZE / 2))
    echo "half_size ${HALF_SIZE}"

    node=$1
    echo $node

    dd if=/dev/zero of=${node} bs=1M count=10

    
    
sfdisk --force ${node} <<EOF
    ${BOOT_ROM_SIZE}M,${KERNEL_DTB_SIZE}M,0c
    $(($KERNEL_DTB_SIZE + ${BOOT_ROM_SIZE}))M,${HALF_SIZE}M,83
    $(($KERNEL_DTB_SIZE + ${BOOT_ROM_SIZE} + ${HALF_SIZE}))M,${HALF_SIZE}M,83
EOF
	partx -u ${node}
	timeout=20
	while [ $timeout -gt 0 ]
	do
	    [ -b ${node}p3 ] && break
	    sleep 0.5
	    timeout=$((timeout - 1))
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
 
}

resize2fs_mmc(){
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

burn_process

echo_fun "start format mmc "
mksdcard ${EMMC_NODE}
echo_fun "start burn dtb and kernel "
burn_kernel_dtb
echo_fun "start burn rootfs "
burn_rootfs_ext4
echo_fun "start burn uboot "
burn_bootloader
resize2fs_mmc
check_rootfs
enable_bootpart
burn_sucesss





