#!/bin/sh

set -eu

PATH=/sbin:/bin:/usr/sbin:/usr/bin

PARTLABEL=encdata
MAPPER_NAME=encdata
MOUNT_POINT=/data
RUN_DIR=/run/myd-js8mpq-caam-dmcrypt
KEY_NAME=myirenc
KEY_BYTES=32
RESERVED_SECTORS=2048
UNINITIALIZED_MAGIC=MYIR_CAAM_DMCRYPT_UNINITIALIZED_V1
STATE_MAGIC=MYIR_CAAM_DMCRYPT_V1
RUN_DIR_CREATED=0
MAPPING_CREATED=0
MOUNT_CREATED=0

log()
{
    echo "myd-js8mpq-caam-dmcrypt: $*"
}

fail()
{
    log "ERROR: $*"
    exit 1
}

wait_for_partition()
{
    timeout=60
    while [ "${timeout}" -gt 0 ]; do
        if [ -e "/dev/disk/by-partlabel/${PARTLABEL}" ]; then
            DATA_DEVICE=$(readlink -f "/dev/disk/by-partlabel/${PARTLABEL}")
            [ -b "${DATA_DEVICE}" ] || fail "${DATA_DEVICE} is not a block device"
            return 0
        fi
        sleep 1
        timeout=$((timeout - 1))
    done
    fail "PARTLABEL=${PARTLABEL} did not appear"
}

read_state_sector()
{
    dd if="${DATA_DEVICE}" bs=512 skip="${STATE_SECTOR}" count=1 2>/dev/null |
        tr -d '\000' > "${RUN_DIR}/state"
}

validate_number()
{
    value=$1
    field=$2
    case "${value}" in
        ''|*[!0-9]*) fail "invalid ${field} in CAAM state" ;;
    esac
}

load_initialized_blob()
{
    blob_bytes=
    blob_sha256=
    data_sectors=
    provisioned=

    while IFS='=' read -r name value; do
        case "${name}" in
            magic) state_magic=${value} ;;
            blob_bytes) blob_bytes=${value} ;;
            blob_sha256) blob_sha256=${value} ;;
            data_sectors) data_sectors=${value} ;;
            provisioned) provisioned=${value} ;;
        esac
    done < "${RUN_DIR}/state"

    [ "${state_magic:-}" = "${STATE_MAGIC}" ] || fail "invalid CAAM state magic"
    validate_number "${blob_bytes}" blob_bytes
    validate_number "${data_sectors}" data_sectors
    [ "${blob_bytes}" -gt 0 ] && [ "${blob_bytes}" -le 512 ] ||
        fail "CAAM blob does not fit its reserved sector"
    [ "${data_sectors}" -eq "${STATE_SECTOR}" ] ||
        fail "CAAM state does not match the data partition size"
    case "${provisioned}" in
        0) FIRST_PROVISION=1 ;;
        1) FIRST_PROVISION=0 ;;
        *) fail "invalid provisioned flag in CAAM state" ;;
    esac
    [ "${#blob_sha256}" -eq 64 ] || fail "invalid CAAM blob checksum length"
    case "${blob_sha256}" in
        *[!0-9a-f]*) fail "invalid CAAM blob checksum" ;;
    esac

    dd if="${DATA_DEVICE}" bs=512 skip=$((STATE_SECTOR + 1)) count=1 2>/dev/null |
        head -c "${blob_bytes}" > "${RUN_DIR}/${KEY_NAME}.bb"

    actual_sha256=$(sha256sum "${RUN_DIR}/${KEY_NAME}.bb" | cut -d' ' -f1)
    [ "${actual_sha256}" = "${blob_sha256}" ] || fail "CAAM blob checksum mismatch"

    caam-keygen import "${RUN_DIR}/${KEY_NAME}.bb" "${KEY_NAME}" ||
        fail "CAAM could not import the device-bound black blob"
}

persist_state()
{
    provisioned=$1
    case "${provisioned}" in
        0|1) ;;
        *) fail "refusing to persist invalid provisioned flag" ;;
    esac

    {
        echo "magic=${STATE_MAGIC}"
        echo "blob_bytes=${blob_bytes}"
        echo "blob_sha256=${blob_sha256}"
        echo "data_sectors=${STATE_SECTOR}"
        echo "provisioned=${provisioned}"
    } > "${RUN_DIR}/state.new"

    state_bytes=$(wc -c < "${RUN_DIR}/state.new")
    [ "${state_bytes}" -le 512 ] || fail "CAAM state is larger than one sector"
    dd if="${RUN_DIR}/state.new" of="${DATA_DEVICE}" bs=512 count=1 \
        seek="${STATE_SECTOR}" conv=sync,notrunc 2>/dev/null ||
        fail "could not persist CAAM state"
    sync
}

initialize_blob()
{
    first_line=$(sed -n '1p' "${RUN_DIR}/state")
    [ "${first_line}" = "${UNINITIALIZED_MAGIC}" ] ||
        fail "encdata is not explicitly marked for first-boot provisioning"

    # A rewritten tail marker must never authorize destructive reprovisioning
    # of an existing encrypted filesystem. The factory script erases the data
    # area, while an initialized dm-crypt filesystem has non-zero ciphertext
    # at its beginning.
    nonzero_bytes=$(dd if="${DATA_DEVICE}" bs=1M count=1 2>/dev/null |
        tr -d '\000' | wc -c)
    [ "${nonzero_bytes}" -eq 0 ] ||
        fail "refusing to reprovision a non-empty encdata partition"

    log "Provisioning a new device-bound CAAM black blob"
    caam-keygen create "${KEY_NAME}" ccm -s "${KEY_BYTES}" ||
        fail "CAAM black key generation failed"

    [ -s "${RUN_DIR}/${KEY_NAME}" ] || fail "tagged black key was not generated"
    [ -s "${RUN_DIR}/${KEY_NAME}.bb" ] || fail "CAAM black blob was not generated"

    blob_bytes=$(wc -c < "${RUN_DIR}/${KEY_NAME}.bb")
    validate_number "${blob_bytes}" blob_bytes
    [ "${blob_bytes}" -le 512 ] || fail "CAAM blob is larger than one sector"
    blob_sha256=$(sha256sum "${RUN_DIR}/${KEY_NAME}.bb" | cut -d' ' -f1)

    dd if=/dev/zero of="${DATA_DEVICE}" bs=512 seek=$((STATE_SECTOR + 1)) \
        count=$((RESERVED_SECTORS - 1)) conv=notrunc 2>/dev/null ||
        fail "could not clear the reserved CAAM state area"
    dd if="${RUN_DIR}/${KEY_NAME}.bb" of="${DATA_DEVICE}" bs=512 \
        seek=$((STATE_SECTOR + 1)) conv=notrunc 2>/dev/null ||
        fail "could not persist the CAAM black blob"

    persist_state 0
    FIRST_PROVISION=1
}

check_kernel_support()
{
    grep -q '^name[[:space:]]*: tk(cbc(aes))$' /proc/crypto ||
        fail "tk(cbc(aes)) is not registered"
    grep -q '^driver[[:space:]]*: tk-cbc-aes-caam$' /proc/crypto ||
        fail "tk(cbc(aes)) is not backed by CAAM"
    dmsetup targets | grep -q '^[[:space:]]*crypt[[:space:]]' ||
        fail "dm-crypt target is not available"
    [ -c /dev/caam-keygen ] || fail "/dev/caam-keygen is not available"
}

open_mapping()
{
    tagged_key="${RUN_DIR}/${KEY_NAME}"
    [ -s "${tagged_key}" ] || fail "tagged black key is missing"
    tagged_key_bytes=$(wc -c < "${tagged_key}")
    validate_number "${tagged_key_bytes}" tagged_key_bytes

    keyctl new_session myd-js8mpq-caam-dmcrypt >/dev/null
    key_serial=$(keyctl padd logon "${KEY_NAME}:" @s < "${tagged_key}") ||
        fail "could not add tagged black key to the session keyring"

    dmsetup create "${MAPPER_NAME}" --table \
        "0 ${STATE_SECTOR} crypt capi:tk(cbc(aes))-plain :${tagged_key_bytes}:logon:${KEY_NAME}: 0 ${DATA_DEVICE} 0 1 sector_size:512" ||
        fail "could not create dm-crypt mapping"
    MAPPING_CREATED=1

    rm -f "${tagged_key}"
    keyctl unlink "${key_serial}" @s >/dev/null 2>&1 || true
}

mount_mapping()
{
    mapped_device="/dev/mapper/${MAPPER_NAME}"
    if [ "${FIRST_PROVISION}" -eq 1 ]; then
        log "Creating the encrypted ext4 filesystem"
        mkfs.ext4 -F -L encdata "${mapped_device}" || fail "mkfs.ext4 failed"
        persist_state 1
        FIRST_PROVISION=0
        log "Encrypted data volume provisioning completed"
    else
        fs_type=$(blkid -s TYPE -o value "${mapped_device}" 2>/dev/null || true)
        [ "${fs_type}" = "ext4" ] || fail "existing encrypted volume is not ext4"
    fi

    mkdir -p "${MOUNT_POINT}"
    mount -t ext4 "${mapped_device}" "${MOUNT_POINT}" || fail "could not mount ${MOUNT_POINT}"
    MOUNT_CREATED=1
    log "Encrypted data volume mounted on ${MOUNT_POINT}"
}

start_volume()
{
    # The encrypted data partition is optional for this image.  On a normal
    # (non-factory-encrypted) layout, return successfully before creating the
    # runtime directory or entering the udev wait loop.
    if [ ! -e "/dev/disk/by-partlabel/${PARTLABEL}" ]; then
        log "PARTLABEL=${PARTLABEL} is absent; skipping encrypted data volume"
        return 0
    fi

    [ ! -e "/dev/mapper/${MAPPER_NAME}" ] || fail "${MAPPER_NAME} mapping already exists"
    [ ! -e "${RUN_DIR}" ] || fail "stale runtime directory ${RUN_DIR} exists"
    mkdir "${RUN_DIR}"
    RUN_DIR_CREATED=1
    chmod 0700 "${RUN_DIR}"
    FIRST_PROVISION=0

    wait_for_partition
    total_sectors=$(blockdev --getsz "${DATA_DEVICE}")
    validate_number "${total_sectors}" total_sectors
    [ "${total_sectors}" -gt "${RESERVED_SECTORS}" ] || fail "encdata partition is too small"
    STATE_SECTOR=$((total_sectors - RESERVED_SECTORS))

    check_kernel_support
    read_state_sector
    if grep -qx "${UNINITIALIZED_MAGIC}" "${RUN_DIR}/state"; then
        initialize_blob
    else
        load_initialized_blob
    fi
    open_mapping
    mount_mapping
}

stop_volume()
{
    if mountpoint -q "${MOUNT_POINT}"; then
        umount "${MOUNT_POINT}" || fail "could not unmount ${MOUNT_POINT}"
    fi
    if [ -e "/dev/mapper/${MAPPER_NAME}" ]; then
        dmsetup remove "${MAPPER_NAME}" || fail "could not remove ${MAPPER_NAME}"
    fi
    rm -rf "${RUN_DIR}"
}

cleanup_failed_start()
{
    status=$?
    trap - 0
    if [ "${status}" -ne 0 ]; then
        log "Rolling back an incomplete startup"
        if [ "${MOUNT_CREATED}" -eq 1 ] &&
           mountpoint -q "${MOUNT_POINT}" 2>/dev/null; then
            umount "${MOUNT_POINT}" 2>/dev/null || true
        fi
        if [ "${MAPPING_CREATED}" -eq 1 ] &&
           [ -e "/dev/mapper/${MAPPER_NAME}" ]; then
            dmsetup remove "${MAPPER_NAME}" 2>/dev/null || true
        fi
        if [ "${RUN_DIR_CREATED}" -eq 1 ]; then
            rm -rf "${RUN_DIR}"
        fi
    fi
    exit "${status}"
}

case "${1:-}" in
    start)
        trap cleanup_failed_start 0
        start_volume
        trap - 0
        ;;
    stop) stop_volume ;;
    *) fail "usage: $0 {start|stop}" ;;
esac
