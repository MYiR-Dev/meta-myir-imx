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

########################################
# LED状态
########################################
burn_process() {
    echo timer > /sys/class/leds/${led1}/trigger
    echo 200 > /sys/class/leds/${led1}/delay_on
    echo 200 > /sys/class/leds/${led1}/delay_off

    echo timer > /sys/class/leds/${led2}/trigger
    echo 200 > /sys/class/leds/${led2}/delay_on
    echo 200 > /sys/class/leds/${led2}/delay_off
}

burn_sucesss() {
    echo timer > /sys/class/leds/${led1}/trigger
    echo 1 > /sys/class/leds/${led1}/delay_on
    echo 0 > /sys/class/leds/${led1}/delay_off

    echo timer > /sys/class/leds/${led2}/trigger
    echo 1 > /sys/class/leds/${led2}/delay_on
    echo 0 > /sys/class/leds/${led2}/delay_off
}

burn_fail() {
    echo timer > /sys/class/leds/${led1}/trigger
    echo 0 > /sys/class/leds/${led1}/delay_on
    echo 1 > /sys/class/leds/${led1}/delay_off

    echo timer > /sys/class/leds/${led2}/trigger
    echo 0 > /sys/class/leds/${led2}/delay_on
    echo 1 > /sys/class/leds/${led2}/delay_off
}

########################################
# 通用函数
########################################
echo_fun() {
    echo "***********************************************" >> ${ECHO_TTY}
    echo "********    $1 ***********" >> ${ECHO_TTY}
    echo "***********************************************" >> ${ECHO_TTY}
}

cmd_check() {
    if [ $1 -ne 0 ]; then
        echo "$2 failed!" >> ${ECHO_TTY}
        burn_fail
        exit -1
    fi
}

########################################
# 分区（A/B结构）
########################################
mksdcard() {

	node=$1
	#partition size in 10M
	BOOT_ROM_SIZE=10
	KERNEL_DTB_SIZE=200
	RESERVED_SIZE=50
	ALIGN_FIX=8
	
	EMMC_SIZE=`cat /sys/block/mmcblk${PART}/size`
	EMMC_SIZE=$((${EMMC_SIZE} * 512 / 1024 / 1024))
	echo EMMC_SIZE ${EMMC_SIZE}
	
	
	AVAILABLE_SIZE=$((EMMC_SIZE - BOOT_ROM_SIZE - KERNEL_DTB_SIZE*2 - RESERVED_SIZE - ALIGN_FIX))
	HALF_SIZE=$((AVAILABLE_SIZE / 2))
	echo "half_size ${HALF_SIZE}"
	
	node=$1
	echo $node
	
	dd if=/dev/zero of=${node} bs=1M count=10
	
	
	START1=${BOOT_ROM_SIZE}
	START2=$((${BOOT_ROM_SIZE} + ${KERNEL_DTB_SIZE}))
	START3=$((${BOOT_ROM_SIZE} + ${KERNEL_DTB_SIZE} + ${HALF_SIZE}))
	START4=$((${BOOT_ROM_SIZE} + ${KERNEL_DTB_SIZE} + ${HALF_SIZE} + ${KERNEL_DTB_SIZE}))
	
	sfdisk --force ${node} <<EOF
	${START1}M,${KERNEL_DTB_SIZE}M,0c
	${START2}M,${HALF_SIZE}M,83
	${START3}M,${KERNEL_DTB_SIZE}M,0c
	${START4}M,${HALF_SIZE}M,83
EOF


    partx -u ${node}


    timeout=20
    while [ $timeout -gt 0 ]; do
        [ -b ${node}p4 ] && break
        sleep 0.5
        timeout=$((timeout - 1))
    done
}

########################################
# Bootloader
########################################
enable_bootpart() {
    mmc bootpart enable 1 1 /dev/mmcblk${PART}
}

burn_bootloader() {
    echo 0 > /sys/block/mmcblk${PART}boot0/force_ro
    dd if=${UBOOT_FILE} of=/dev/mmcblk${PART}boot0
    cmd_check $? "burn uboot failed"
    sync
    echo 1 > /sys/block/mmcblk${PART}boot0/force_ro
}

########################################
# BOOT_A / BOOT_B
########################################
burn_kernel_dtb() {
    for index in 1 3
    do
        mkfs.vfat /dev/mmcblk${PART}p${index}

        mkdir -p /mnt/mmcblk${PART}p${index}
        mount -t vfat /dev/mmcblk${PART}p${index} /mnt/mmcblk${PART}p${index}

        cp ${KERNEL_DTB_DIR}/* /mnt/mmcblk${PART}p${index}
        cmd_check $? "burn kernel/dtb failed"

        sync
        umount /mnt/mmcblk${PART}p${index}
    done
}

########################################
# ROOTFS_A / ROOTFS_B
########################################
burn_rootfs_ext4() {
    for index in 2 4
    do
        mkfs.ext4 /dev/mmcblk${PART}p${index} <<EOF
y
EOF
        dd if=${ROOTFS_FILE_EXT4} of=/dev/mmcblk${PART}p${index} bs=1M
        cmd_check $? "burn rootfs failed"
        sync
    done
}

resize2fs_mmc() {
    for index in 2 4
    do
        resize2fs /dev/mmcblk${PART}p${index}
        cmd_check $? "resize2fs failed"
        sync
    done
}

########################################
# 校验
########################################
check_rootfs() {
    for index in 2 4
    do
        mkdir -p /mnt/mmcblk${PART}p${index}
        mount /dev/mmcblk${PART}p${index} /mnt/mmcblk${PART}p${index}

        rootfs_hostname=`cat /mnt/mmcblk${PART}p${index}/etc/hostname`
        echo_fun "p${index} hostname: $rootfs_hostname"

        umount /mnt/mmcblk${PART}p${index}
    done
}

########################################
# 主流程
########################################
burn_process

echo_fun "start format mmc"
mksdcard ${EMMC_NODE}

echo_fun "burn kernel & dtb (A/B)"
burn_kernel_dtb

echo_fun "burn rootfs (A/B)"
burn_rootfs_ext4

echo_fun "burn uboot"
burn_bootloader

resize2fs_mmc
check_rootfs
enable_bootpart

burn_sucesss
