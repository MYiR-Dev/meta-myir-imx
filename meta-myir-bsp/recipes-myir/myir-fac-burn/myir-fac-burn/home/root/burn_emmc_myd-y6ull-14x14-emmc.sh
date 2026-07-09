#!/bin/sh
PART=1
EMMC_NODE=/dev/mmcblk${PART}

UBOOT_FILE=/root/mfgimage/u-boot.imx
KERNEL_DTB_DIR=/root/mfgimage/kernel_dtb
ROOTFS_FILE_EXT4=/root/mfgimage/rootfs-full.ext4

MYD_NAME="myd-y6ull-14x14-emmc"


HOSTNAME=`cat /etc/hostname`

led=heartbeat

ECHO_TTY="/dev/ttymxc0"


burn_process()
{
        echo timer > /sys/class/leds/${led}/trigger
        echo 200 >  /sys/class/leds/${led}/delay_on
        echo 200 >  /sys/class/leds/${led}/delay_off
}


burn_sucesss()
{
        echo timer > /sys/class/leds/${led}/trigger
        echo 1 >  /sys/class/leds/${led}/delay_on
        echo 0 >  /sys/class/leds/${led}/delay_off
}
burn_fail()
{
        echo timer > /sys/class/leds/${led}/trigger
        echo 0 >  /sys/class/leds/${led}/delay_on
        echo 1 >  /sys/class/leds/${led}/delay_off
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
    #partition size in 10M
    BOOT_ROM_SIZE=10
    KERNEL_DTB_SIZE=200

    if [   $# -lt 1 ];then
	echo format node not exist
        exit 1
    else
	echo exist
    fi
    node=$1
    echo $node

    umount /dev/mmcblk${PART}p1
    umount /dev/mmcblk${PART}p2
    sync
    sleep 1

    dd if=/dev/zero of=${node} bs=1M count=10

    
    
sfdisk --force ${node} <<EOF
    ${BOOT_ROM_SIZE}M,${KERNEL_DTB_SIZE}M,0c
    $(($KERNEL_DTB_SIZE + 10))M,,83
EOF
	partx -u ${node}
	timeout=20
	while [ $timeout -gt 0 ]
	do
	    [ -b ${node}p2 ] && break
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
    dd if=${UBOOT_FILE} of=/dev/mmcblk${PART}boot0 bs=512 seek=2 conv=fsync

    cmd_check $? "burn uboot faild"
    sleep 1


    echo 1 > /sys/block/mmcblk${PART}boot0/force_ro
}

burn_kernel_dtb(){
    mkfs.vfat  /dev/mmcblk${PART}p1
    mkdir -p /mnt/boot-mmcblk${PART}p1
    mount -t vfat /dev/mmcblk${PART}p1 /mnt/boot-mmcblk${PART}p1
    cp ${KERNEL_DTB_DIR}/* /mnt/boot-mmcblk${PART}p1
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

resize2fs_mmc(){
    resize2fs /dev/mmcblk${PART}p2
    cmd_check $? "reszie2fs mmc faild"
    sync
}

check_rootfs(){
    mkdir -p /run/media/rootfs-mmcblk1p2
    mount /dev/mmcblk${PART}p2 /run/media/rootfs-mmcblk1p2
    rootfs_hostname=`cat /run/media/rootfs-mmcblk1p2/etc/hostname`
    echo_fun "rootfs_hostname:$rootfs_hostname"
    if [ "x$rootfs_hostname" != "x$HOSTNAME" ]; then
        echo_fun "hostname mismatch"
        burn_fail
        exit 1
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




