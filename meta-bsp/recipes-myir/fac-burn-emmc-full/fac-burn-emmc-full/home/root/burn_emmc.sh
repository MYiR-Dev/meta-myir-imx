#!/bin/sh
PART=2
EMMC_NODE=/dev/mmcblk${PART}

UBOOT_FILE=/home/root/mfgimage/imx-boot
KERNEL_DTB_DIR=/home/root/mfgimage/kernel_dtb
ROOTFS_FILE_EXT4=/home/root/mfgimage/rootfs-full.ext4
enable_light(){
    killall /home/root/light.sh  > /dev/null
    /home/root/light.sh $1 &
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

    dd if=/dev/zero of=${node} bs=1024 count=1

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
    dd if=${UBOOT_FILE} of=/dev/mmcblk${PART}boot0 bs=1k seek=33
    echo 1 > /sys/block/mmcblk${PART}boot0/force_ro
}

burn_kernel_dtb(){
    mkfs.vfat  /dev/mmcblk${PART}p1
    mkdir -p /mnt/mmcblk${PART}p1
    mount -t vfat /dev/mmcblk${PART}p1 /mnt/mmcblk${PART}p1
    cp ${KERNEL_DTB_DIR}/* /mnt/mmcblk${PART}p1
    sync
}


burn_rootfs_ext4(){
    start_time=`date +%s`
    mkfs.ext4  /dev/mmcblk${PART}p2 <<EOF
y
EOF
    dd if=${ROOTFS_FILE_EXT4} of=/dev/mmcblk${PART}p2 bs=1M
    sync
    end_time=`date +%s`
    echo rootfs time:$(($end_time - $start_time))
}

enable_light 1 
mksdcard ${EMMC_NODE}
burn_kernel_dtb 
enable_light 0.2
burn_rootfs_ext4
burn_bootloader 
enable_bootpart
enable_light 2
reboot



