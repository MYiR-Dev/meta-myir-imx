#!/bin/sh

UBOOT_FILE=/root/mfgimage/imx-boot
KERNEL_DTB_DIR=/root/mfgimage/kernel_dtb
ROOTFS_FILE_EXT4=/root/mfgimage/rootfs-full.ext4
ECHO_TTY=/dev/ttymxc1
LED_NAME=blue
BURN_PROCESS_PID=

log()
{
    echo "$*"
    if [ -w "${ECHO_TTY}" ]; then
        echo "$*" > "${ECHO_TTY}"
    fi
}

stop_burn_process()
{
    if [ -n "${BURN_PROCESS_PID}" ]; then
        kill "${BURN_PROCESS_PID}" 2>/dev/null || true
        wait "${BURN_PROCESS_PID}" 2>/dev/null || true
        BURN_PROCESS_PID=
    fi
}

burn_process()
{
    while true; do
        log "Updating..."
        sleep 2
    done
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
    stop_burn_process
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
    boot_gap_mib=10
    boot_slot_mib=256
    end_reserved_mib=64
    emmc_sectors=$(cat "/sys/block/${EMMC_NAME}/size")
    emmc_mib=$((emmc_sectors * 512 / 1024 / 1024))
    available_mib=$((emmc_mib - boot_gap_mib - boot_slot_mib * 2 - end_reserved_mib))

    [ "${available_mib}" -gt 0 ] || fail "${EMMC_NODE} is too small for A/B partitions"
    rootfs_slot_mib=$((available_mib / 2))

    rootfs_bytes=$(wc -c < "${ROOTFS_FILE_EXT4}")
    rootfs_image_mib=$(((rootfs_bytes + 1024 * 1024 - 1) / 1024 / 1024))
    [ "${rootfs_image_mib}" -le "${rootfs_slot_mib}" ] ||
        fail "rootfs image (${rootfs_image_mib} MiB) does not fit ${rootfs_slot_mib} MiB A/B slot"

    rootfs_a_start_mib=$((boot_gap_mib + boot_slot_mib))
    boot_b_start_mib=$((rootfs_a_start_mib + rootfs_slot_mib))
    rootfs_b_start_mib=$((boot_b_start_mib + boot_slot_mib))

    log "Partitioning ${EMMC_NODE}: ${emmc_mib} MiB, each rootfs slot ${rootfs_slot_mib} MiB"
    dd if=/dev/zero of="${EMMC_NODE}" bs=1M count=10 conv=fsync ||
        fail "failed to clear the eMMC partition table"

    sfdisk --force "${EMMC_NODE}" <<EOF || fail "failed to partition eMMC"
${boot_gap_mib}M,${boot_slot_mib}M,0c,*
${rootfs_a_start_mib}M,${rootfs_slot_mib}M,83
${boot_b_start_mib}M,${boot_slot_mib}M,0c
${rootfs_b_start_mib}M,${rootfs_slot_mib}M,83
EOF

    partx -u "${EMMC_NODE}" || fail "failed to update eMMC partitions"

    timeout=40
    while [ "${timeout}" -gt 0 ]; do
        if [ -b "${EMMC_NODE}p1" ] && [ -b "${EMMC_NODE}p2" ] &&
           [ -b "${EMMC_NODE}p3" ] && [ -b "${EMMC_NODE}p4" ]; then
            return 0
        fi
        sleep 0.5
        timeout=$((timeout - 1))
    done
    fail "eMMC A/B partitions did not appear"
}

burn_boot_partitions()
{
    for boot_part in 1 3; do
        if [ "${boot_part}" -eq 1 ]; then
            slot=A
        else
            slot=B
        fi
        mount_dir=/mnt/${EMMC_NAME}p${boot_part}

        log "Writing boot slot ${slot} (${EMMC_NODE}p${boot_part})"
        mkfs.vfat -n "BOOT_${slot}" "${EMMC_NODE}p${boot_part}" ||
            fail "failed to format boot slot ${slot}"
        mkdir -p "${mount_dir}"
        mount -t vfat "${EMMC_NODE}p${boot_part}" "${mount_dir}" ||
            fail "failed to mount boot slot ${slot}"
        cp -R "${KERNEL_DTB_DIR}"/. "${mount_dir}"/ ||
            fail "failed to copy kernel and device trees to slot ${slot}"
        sync
        umount "${mount_dir}" || fail "failed to unmount boot slot ${slot}"
    done
}

burn_rootfs_partitions()
{
    for rootfs_part in 2 4; do
        if [ "${rootfs_part}" -eq 2 ]; then
            slot=A
        else
            slot=B
        fi

        log "Writing root filesystem slot ${slot} (${EMMC_NODE}p${rootfs_part})"
        dd if="${ROOTFS_FILE_EXT4}" of="${EMMC_NODE}p${rootfs_part}" bs=4M conv=fsync ||
            fail "failed to write root filesystem slot ${slot}"
        status=0
        e2fsck -f -y "${EMMC_NODE}p${rootfs_part}" || status=$?
        [ "${status}" -le 1 ] || fail "root filesystem slot ${slot} check failed"
        resize2fs "${EMMC_NODE}p${rootfs_part}" ||
            fail "failed to resize root filesystem slot ${slot}"
    done
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

verify_rootfs_partitions()
{
    expected=$(cat /etc/hostname)

    for rootfs_part in 2 4; do
        if [ "${rootfs_part}" -eq 2 ]; then
            slot=A
        else
            slot=B
        fi
        mount_dir=/mnt/${EMMC_NAME}p${rootfs_part}

        mkdir -p "${mount_dir}"
        mount -o ro "${EMMC_NODE}p${rootfs_part}" "${mount_dir}" ||
            fail "failed to mount root filesystem slot ${slot}"
        actual=$(cat "${mount_dir}/etc/hostname" 2>/dev/null)
        umount "${mount_dir}" || fail "failed to unmount root filesystem slot ${slot}"
        [ "${actual}" = "${expected}" ] ||
            fail "root filesystem slot ${slot} verification failed"
        log "Verified root filesystem slot ${slot}"
    done
}

set_led timer
find_emmc
check_inputs
check_not_running_from_emmc

log "Factory A/B burn target: ${EMMC_NODE}"
burn_process &
BURN_PROCESS_PID=$!
partition_emmc
burn_boot_partitions
burn_rootfs_partitions
burn_bootloader
verify_rootfs_partitions
sync

stop_burn_process
set_led heartbeat
log "Factory A/B burn completed successfully"
