#!/bin/sh

UBOOT_FILE=/root/mfgimage/imx-boot
KERNEL_DTB_DIR=/root/mfgimage/kernel_dtb
ROOTFS_FILE_EXT4=/root/mfgimage/rootfs-full.ext4
ECHO_TTY=/dev/ttymxc1
LED_NAME=blue

log()
{
    echo "$*"
    if [ -w "${ECHO_TTY}" ]; then
        echo "$*" > "${ECHO_TTY}"
    fi
}

set_led()
{
    trigger=$1
    led_dir=/sys/class/leds/${LED_NAME}

    [ -d "${led_dir}" ] || return 0
    echo "${trigger}" > "${led_dir}/trigger"
}

fail()
{
    log "ERROR: $*"
    set_led none
    if [ -w "/sys/class/leds/${LED_NAME}/brightness" ]; then
        echo 0 > "/sys/class/leds/${LED_NAME}/brightness"
    fi
    exit 1
}

find_emmc()
{
    found=

    for sysdev in /sys/block/mmcblk[0-9]*; do
        [ -r "${sysdev}/device/type" ] || continue
        [ "$(cat "${sysdev}/device/type")" = "MMC" ] || continue

        devname=${sysdev##*/}
        if [ -n "${found}" ]; then
            fail "multiple eMMC devices found: ${found} and ${devname}"
        fi
        found=${devname}
    done

    [ -n "${found}" ] || fail "no eMMC device found"
    EMMC_NAME=${found}
    EMMC_NODE=/dev/${found}
    [ -b "${EMMC_NODE}" ] || fail "${EMMC_NODE} is not a block device"
    [ -b "/dev/${EMMC_NAME}boot0" ] || fail "${EMMC_NAME} has no boot0 partition"
}

check_inputs()
{
    [ -f "${UBOOT_FILE}" ] || fail "missing ${UBOOT_FILE}"
    [ -d "${KERNEL_DTB_DIR}" ] || fail "missing ${KERNEL_DTB_DIR}"
    [ -f "${ROOTFS_FILE_EXT4}" ] || fail "missing ${ROOTFS_FILE_EXT4}"
}

check_not_running_from_emmc()
{
    root_source=$(findmnt -n -o SOURCE / 2>/dev/null || true)
    case "${root_source}" in
        ${EMMC_NODE}|${EMMC_NODE}p*)
            fail "refusing to overwrite the active root device ${root_source}"
            ;;
    esac
}

partition_emmc()
{
    log "Partitioning ${EMMC_NODE}"
    dd if=/dev/zero of="${EMMC_NODE}" bs=1M count=10 conv=fsync ||
        fail "failed to clear the eMMC partition table"

    sfdisk --force "${EMMC_NODE}" <<EOF || fail "failed to partition eMMC"
10M,256M,0c,*
266M,,83
EOF

    partx -u "${EMMC_NODE}" || fail "failed to update eMMC partitions"

    timeout=40
    while [ "${timeout}" -gt 0 ]; do
        [ -b "${EMMC_NODE}p1" ] && [ -b "${EMMC_NODE}p2" ] && return 0
        sleep 0.5
        timeout=$((timeout - 1))
    done
    fail "eMMC partitions did not appear"
}

burn_boot_partition()
{
    mount_dir=/mnt/${EMMC_NAME}p1

    log "Writing boot partition"
    mkfs.vfat "${EMMC_NODE}p1" || fail "failed to format boot partition"
    mkdir -p "${mount_dir}"
    mount -t vfat "${EMMC_NODE}p1" "${mount_dir}" ||
        fail "failed to mount boot partition"
    cp -R "${KERNEL_DTB_DIR}"/. "${mount_dir}"/ ||
        fail "failed to copy kernel and device trees"
    sync
    umount "${mount_dir}" || fail "failed to unmount boot partition"
}

burn_rootfs()
{
    log "Writing root filesystem"
    dd if="${ROOTFS_FILE_EXT4}" of="${EMMC_NODE}p2" bs=4M conv=fsync ||
        fail "failed to write root filesystem"
    e2fsck -f -y "${EMMC_NODE}p2" || status=$?
    [ "${status:-0}" -le 1 ] || fail "root filesystem check failed"
    resize2fs "${EMMC_NODE}p2" || fail "failed to resize root filesystem"
}

burn_bootloader()
{
    boot0=/dev/${EMMC_NAME}boot0
    force_ro=/sys/block/${EMMC_NAME}boot0/force_ro

    log "Writing i.MX boot container"
    echo 0 > "${force_ro}" || fail "failed to unlock eMMC boot0"
    dd if="${UBOOT_FILE}" of="${boot0}" bs=1M conv=fsync ||
        fail "failed to write i.MX boot container"
    echo 1 > "${force_ro}" || fail "failed to relock eMMC boot0"
    mmc bootpart enable 1 1 "${EMMC_NODE}" ||
        fail "failed to enable eMMC boot0"
}

verify_rootfs()
{
    mount_dir=/mnt/${EMMC_NAME}p2
    expected=$(cat /etc/hostname)

    mkdir -p "${mount_dir}"
    mount -o ro "${EMMC_NODE}p2" "${mount_dir}" ||
        fail "failed to mount written root filesystem"
    actual=$(cat "${mount_dir}/etc/hostname" 2>/dev/null)
    umount "${mount_dir}"
    [ "${actual}" = "${expected}" ] ||
        fail "root filesystem verification failed"
}

set_led timer
find_emmc
check_inputs
check_not_running_from_emmc

log "Factory burn target: ${EMMC_NODE}"
partition_emmc
burn_boot_partition
burn_rootfs
burn_bootloader
verify_rootfs
sync

set_led heartbeat
log "Factory burn completed successfully"
