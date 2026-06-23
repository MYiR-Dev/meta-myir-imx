#!/bin/sh

# MYIR encryption handler

# backend used to manage the encryption key
MYIR_ENC_KEY_BACKEND="@@MYIR_ENC_KEY_BACKEND@@"

# cipher preset
MYIR_ENC_CIPHER="@@MYIR_ENC_CIPHER@@"

# dm-crypt cipher specification (initialized at runtime)
MYIR_ENC_CIPHER_SPEC=""

# encryption key size in bytes (initialized at runtime)
MYIR_ENC_KEY_SIZE=""

# encryption key location
MYIR_ENC_KEY_LOCATION="@@MYIR_ENC_KEY_LOCATION@@"

# directory to store encrypted key
MYIR_ENC_KEY_DIR="@@MYIR_ENC_KEY_DIR@@"

# key file name
MYIR_ENC_KEY_FILE="@@MYIR_ENC_KEY_FILE@@"

# storage location to be encrypted (e.g. partition)
MYIR_ENC_STORAGE_LOCATION="@@MYIR_ENC_STORAGE_LOCATION@@"

# Number of blocks to reserve from the partition to be encrypted
# Useful in case one needs a storage location to save data in raw
# mode, outside the dm-crypt partition
MYIR_ENC_STORAGE_RESERVE="@@MYIR_ENC_STORAGE_RESERVE@@"

# number of blocks in the storage to be encrypted by dm-crypt
# depends on the size of the partition and the number of blocks
# reserved (see MYIR_ENC_STORAGE_RESERVE), initialized at runtime
MYIR_ENC_STORAGE_NUM_BLOCKS=""

# directory to mount the encrypted storage
MYIR_ENC_STORAGE_MOUNTPOINT="@@MYIR_ENC_STORAGE_MOUNTPOINT@@"

# extra arguments to mkfs; used when running mkfs on the encrypted storage
MYIR_ENC_STORAGE_MKFS_ARGS="@@MYIR_ENC_STORAGE_MKFS_ARGS@@"

# extra arguments to mount; used when mounting the fs stored on the encrypted storage
MYIR_ENC_STORAGE_MOUNT_ARGS="@@MYIR_ENC_STORAGE_MOUNT_ARGS@@"

# dm-crypt device to be created
MYIR_ENC_DM_DEVICE="encdata"

# flag to enable preservation of data on partition before encryption
MYIR_ENC_PRESERVE_DATA=@@MYIR_ENC_PRESERVE_DATA@@

# storage location of data backup file (if needed)
MYIR_ENC_BACKUP_FILE="/tmp/encdata.tar.bz2"

# Configurable RAM use percentage
MYIR_ENC_BACKUP_STORAGE_PCT=@@MYIR_ENC_BACKUP_STORAGE_PCT@@

# encryption key full path
MYIR_ENC_KEY_FULLPATH="${MYIR_ENC_KEY_DIR}/${MYIR_ENC_KEY_FILE}"

# name of the key in the kernel keyring
MYIR_ENC_KEY_KEYRING_NAME="myirenc"

# type of the key in the kernel keyring (depends on the backend and initialized at runtime)
MYIR_ENC_KEY_KEYRING_TYPE=""

# log to standard output
myir_enc_log() {
    echo "${MYIR_ENC_KEY_BACKEND}: $*"
}

# log error message and exit
myir_enc_exit_error() {
    myir_enc_log "ERROR: $*"
    exit 1
}

# setup dm-crypt cipher spec and key size
myir_enc_cipher_configure() {
    case "${MYIR_ENC_CIPHER}" in
        aes-cbc)
            MYIR_ENC_CIPHER_SPEC="cbc(aes)-plain"
            MYIR_ENC_KEY_SIZE="32"
            ;;
        aes-xts)
            MYIR_ENC_CIPHER_SPEC="xts(aes)-plain64"
            MYIR_ENC_KEY_SIZE="64"
            ;;
        *)
            myir_enc_exit_error "Unsupported cipher preset '${MYIR_ENC_CIPHER}'!"
            ;;
    esac
    myir_enc_log "Cipher: ${MYIR_ENC_CIPHER} (${MYIR_ENC_CIPHER_SPEC}, key=${MYIR_ENC_KEY_SIZE} bytes)"
}

# All backends: prepare and check system
myir_enc_prepare_generic() {
    myir_enc_log "Preparing and checking system (generic)..."

    if ! modprobe dm-crypt; then
        myir_enc_exit_error "Error loading dm-crypt module!"
    fi

    if ! dmsetup targets | grep crypt -q; then
        myir_enc_exit_error "No support for dm-crypt target!"
    fi

    MYIR_ENC_STORAGE_NUM_BLOCKS=$(blockdev --getsz ${MYIR_ENC_STORAGE_LOCATION})
    if [ "${MYIR_ENC_KEY_LOCATION}" = "partition" ] && [ "${MYIR_ENC_STORAGE_RESERVE}" = "0" ]; then
        if [ "${MYIR_ENC_CIPHER}" = "aes-cbc" ]; then
            MYIR_ENC_STORAGE_RESERVE="1"
        else
            MYIR_ENC_STORAGE_RESERVE="4"
        fi
    fi

    if [ "${MYIR_ENC_KEY_LOCATION}" = "partition" ] && [ "${MYIR_ENC_CIPHER}" = "aes-xts" ]; then
        if [ "${MYIR_ENC_STORAGE_RESERVE}" -lt 2 ]; then
            myir_enc_exit_error "MYIR_ENC_STORAGE_RESERVE must be at least 2 when using aes-xts with partition key location!"
        fi
    fi

    MYIR_ENC_STORAGE_NUM_BLOCKS=$((MYIR_ENC_STORAGE_NUM_BLOCKS - MYIR_ENC_STORAGE_RESERVE))

    myir_enc_log "Blocks to be encrypted: $MYIR_ENC_STORAGE_NUM_BLOCKS..."
    myir_enc_log "Reserved blocks: $MYIR_ENC_STORAGE_RESERVE..."

    if [ "${MYIR_ENC_KEY_LOCATION}" = "partition" ]; then
        MYIR_ENC_KEY_DIR="/tmp"
        MYIR_ENC_KEY_FULLPATH="${MYIR_ENC_KEY_DIR}/${MYIR_ENC_KEY_FILE}"
        myir_enc_key_recover_from_partition
    fi
}

# CLEARTEXT: prepare system
myir_enc_prepare_cleartext() {
    myir_enc_log "Preparing and checking system (cleartext)..."
}

# CAAM: prepare system
myir_enc_prepare_caam() {
    myir_enc_log "Preparing and checking system (caam)..."

    if ! modprobe trusted source=caam; then
        myir_enc_exit_error "Error loading trusted module!"
    fi
}

# TPM: prepare system
myir_enc_prepare_tpm() {
    myir_enc_log "Preparing and checking system (tpm)..."

    if ! modprobe trusted source=tpm; then
        myir_enc_exit_error "Error loading trusted module!"
    fi

    if [ ! -c /dev/tpm0 ]; then
        myir_enc_exit_error "TPM device node (/dev/tpm0) not found!"
    fi

    if ! echo "deadbeef" | tpm2_hash >/dev/null; then
        myir_enc_exit_error "Hash calculation via tpm2_hash failed. TPM device might not be functional!"
    fi
}

# TEE: prepare system
myir_enc_prepare_tee() {
    myir_enc_log "Preparing and checking system (tee)..."

    if [ ! -c /dev/tee0 ]; then
        myir_enc_exit_error "TEE device node not found!"
    fi

    if ! pgrep "tee-supplicant" > /dev/null; then
        myir_enc_exit_error "TEE supplicant daemon not running!"
    fi

    if ! modprobe trusted source=tee; then
        myir_enc_exit_error "Error loading trusted module!"
    fi
}

myir_enc_key_recover_from_partition() {
    myir_enc_log "Recovering encrypted key blob from partition ${MYIR_ENC_STORAGE_LOCATION}..."

    rm -rf $MYIR_ENC_KEY_FULLPATH

    STORAGE_KEY_BLOCK_DATA=$(mktemp /tmp/myir-enc.XXXXXXXXXX)
    if ! dd if=${MYIR_ENC_STORAGE_LOCATION} of=${STORAGE_KEY_BLOCK_DATA} skip=${MYIR_ENC_STORAGE_NUM_BLOCKS} bs=512 count=${MYIR_ENC_STORAGE_RESERVE}; then
        rm -f "${STORAGE_KEY_BLOCK_DATA}"
        myir_enc_exit_error "Could not read block from ${MYIR_ENC_STORAGE_LOCATION} with key information!"
    fi

    EOT=$(printf '\004')
    while read -r line; do
        echo "$line" | grep -q "$EOT" && break
        key=$(echo "$line" | cut -d'=' -f1)
        val=$(echo "$line" | cut -d'=' -f2)
        case "$key" in
            "keyname") keyname="${val}" ;;
            "keydata") keydata="${val}" ;;
            "keycsum") keycsum="${val}" ;;
        esac
    done < ${STORAGE_KEY_BLOCK_DATA}
    rm -f "${STORAGE_KEY_BLOCK_DATA}"

    if [ "${keyname}" != "${MYIR_ENC_KEY_KEYRING_NAME}" ]; then
        myir_enc_log "Invalid key name! A new key will be created."
        return 1
    fi

    if [ -z "${keydata}" ]; then
        myir_enc_log "Invalid key data! A new key will be created."
        return 1
    fi

    csum=$(printf "%s" "${keydata}" | sha256sum | cut -d' ' -f1)
    if [ "${csum}" != "${keycsum}" ]; then
        myir_enc_log "Invalid checksum! A new key will be created."
        return 1
    fi

    echo "${keydata}" > ${MYIR_ENC_KEY_FULLPATH}
    myir_enc_log "Encrypted key blob successfully recovered from partition."
}

myir_enc_key_save_to_partition() {
    myir_enc_log "Saving encrypted key to partition ${MYIR_ENC_STORAGE_LOCATION}..."

    STORAGE_KEY_BLOCK_DATA=$(mktemp /tmp/myir-enc.XXXXXXXXXX)
    {
        echo "keyname=${MYIR_ENC_KEY_KEYRING_NAME}"
        echo "keydata=$(cat ${MYIR_ENC_KEY_FULLPATH})"
        echo "keycsum=$(sha256sum ${MYIR_ENC_KEY_FULLPATH} | cut -d' ' -f1)"
        printf "\04"
    } > ${STORAGE_KEY_BLOCK_DATA}

    if ! dd if=${STORAGE_KEY_BLOCK_DATA} of=${MYIR_ENC_STORAGE_LOCATION} seek=${MYIR_ENC_STORAGE_NUM_BLOCKS} bs=512; then
        rm -f "${STORAGE_KEY_BLOCK_DATA}"
        myir_enc_exit_error "Could not save encrypted key to partition ${MYIR_ENC_STORAGE_LOCATION}!"
    fi
    rm -f "${STORAGE_KEY_BLOCK_DATA}"
}

# configure key in kernel keyring
myir_enc_keyring_configure() {
    MYIR_ENC_KEY_KEYRING_TYPE="$1"
    KEYNAME="$2"
    NEW_KEY_CMD="$3"
    LOAD_KEY_CMD="$4"

    myir_enc_log "Configuring key in kernel keyring (type=$MYIR_ENC_KEY_KEYRING_TYPE keyname=$KEYNAME)..."

    keyctl new_session ${KEYNAME}_session

    if [ ! -e "${MYIR_ENC_KEY_FULLPATH}" ]; then
        myir_enc_log "Key blob not found. Creating it..."
        KEYHANDLE="$(keyctl add "${MYIR_ENC_KEY_KEYRING_TYPE}" "${KEYNAME}" "$(eval echo ${NEW_KEY_CMD})" @s)"
        mkdir -p "${MYIR_ENC_KEY_DIR}"
        MYIR_ENC_KEY_TMPPATH=$(mktemp "${MYIR_ENC_KEY_DIR}/myir-enc.XXXXXXXXXX")
        if ! keyctl pipe "$KEYHANDLE" > "${MYIR_ENC_KEY_TMPPATH}"; then
            rm -f "${MYIR_ENC_KEY_TMPPATH}"
            myir_enc_exit_error "Error saving key blob!"
        fi
        mv "${MYIR_ENC_KEY_TMPPATH}" "${MYIR_ENC_KEY_FULLPATH}"
        if [ "${MYIR_ENC_KEY_LOCATION}" = "partition" ]; then
            myir_enc_key_save_to_partition
            rm -f "${MYIR_ENC_KEY_FULLPATH}"
        fi
    else
        myir_enc_log "Encrypted key exists. Importing it..."
        keyctl add "${MYIR_ENC_KEY_KEYRING_TYPE}" "${KEYNAME}" "$(eval echo ${LOAD_KEY_CMD})" @s
        if [ "${MYIR_ENC_KEY_LOCATION}" = "partition" ]; then
            rm -f "${MYIR_ENC_KEY_FULLPATH}"
        fi
    fi

    if ! keyctl list @s | grep -q "${MYIR_ENC_KEY_KEYRING_TYPE}: ${KEYNAME}"; then
        myir_enc_exit_error "Error adding key to kernel keyring!"
    fi
}

# CLEARTEXT: generate/load key
# the key is generated by using the SoM serial number and no salt,
# so it is reproducible and doesn't need to be stored in a
# persistent storage device. This is very insecure, but we
# don't care about it, since the 'cleartext' backend is only
# for testing purposes.
myir_enc_key_gen_cleartext() {
    myir_enc_log "Setting up encryption key for cleartext backend..."
    SN=$(cat /sys/firmware/devicetree/base/serial-number)
    KEY=$(openssl enc -pbkdf2 -aes-128-ecb -nosalt -k "${SN}" -P | cut -d'=' -f 2)
    myir_enc_keyring_configure "user" "${MYIR_ENC_KEY_KEYRING_NAME}" "${KEY}" "${KEY}"
}

# CAAM: generate/load key
myir_enc_key_gen_caam() {
    myir_enc_log "Setting up encryption key for CAAM backend..."
    myir_enc_keyring_configure "trusted" "${MYIR_ENC_KEY_KEYRING_NAME}" "new ${MYIR_ENC_KEY_SIZE}" "load \$(cat ${MYIR_ENC_KEY_FULLPATH})"
}

# TPM: generate/load key
myir_enc_key_gen_tpm() {
    myir_enc_log "Setting up encryption key for TPM backend..."

    if [ ! -e "${MYIR_ENC_KEY_FULLPATH}" ]; then
        TPM_KEY_CTXT=$(mktemp /tmp/myir-enc.XXXXXXXXXX)

        # create a private RSA key in the TPM
        if ! tpm2_createprimary -C o -G rsa2048 -c "${TPM_KEY_CTXT}"; then
            rm -f "${TPM_KEY_CTXT}"
            myir_enc_exit_error "Error creating a private RSA key in the TPM!"
        fi

        # make the key persistent
        TPMKEYHANDLE=$(tpm2_evictcontrol -C o -c "${TPM_KEY_CTXT}" | grep persistent-handle | cut -d' ' -f 2)
        rm -f "${TPM_KEY_CTXT}"
        if [ -z "$TPMKEYHANDLE" ]; then
            myir_enc_exit_error "Error making the TPM key persistent!"
        fi
    fi

    myir_enc_keyring_configure "trusted" "${MYIR_ENC_KEY_KEYRING_NAME}" \
                              "new ${MYIR_ENC_KEY_SIZE} keyhandle=$TPMKEYHANDLE" \
                              "load \$(cat ${MYIR_ENC_KEY_FULLPATH})"
}

# TEE: generate/load key
myir_enc_key_gen_tee() {
    myir_enc_log "Setting up encryption key for TEE backend..."
    myir_enc_keyring_configure "trusted" "${MYIR_ENC_KEY_KEYRING_NAME}" "new ${MYIR_ENC_KEY_SIZE}" "load \$(cat ${MYIR_ENC_KEY_FULLPATH})"
}

# initially mount the partition if possible
myir_enc_pre_mount() {
    myir_enc_log "Attempting partition pre-mount"

    if source=$(findmnt -no SOURCE "${MYIR_ENC_STORAGE_MOUNTPOINT}"); then
        if [ "${source}" = "${MYIR_ENC_STORAGE_LOCATION}" ]; then
            myir_enc_log "Partition is already mounted to the specified location."
            return 0
        fi

        myir_enc_exit_error "Mount location already points to a different storage location."
    fi

    mkdir -p "${MYIR_ENC_STORAGE_MOUNTPOINT}"
    if ! mount ${MYIR_ENC_STORAGE_LOCATION} "${MYIR_ENC_STORAGE_MOUNTPOINT}"; then
        myir_enc_log "Unable to mount location, possibly already encrypted..."
        return 1
    fi
    return 0
}

# backup original data in partition (if not encrypted)
myir_enc_backup_data() {
    if [ ${MYIR_ENC_PRESERVE_DATA} -ne 1 ]; then
        myir_enc_log "Data preservation is not enabled"
        return 0
    fi

    myir_enc_log "Backing up original content..."
    MYIR_ENC_BACKUP_FILE=$(mktemp)
    MEM_FREE=$(grep MemFree: /proc/meminfo | tr -s ' ' | cut -d ' ' -f 2)
    BACKUP_STORAGE_LIMIT=$((MEM_FREE * MYIR_ENC_BACKUP_STORAGE_PCT / 100))
    myir_enc_log "Backup limit determined: ${BACKUP_STORAGE_LIMIT}"
    
    msgs="$({ { tar -C "${MYIR_ENC_STORAGE_MOUNTPOINT}" -c . || echo "ERROR" >&2; } | { bzip2 -cz || echo "ERROR" >&2; } | dd bs=1024 count=${BACKUP_STORAGE_LIMIT} of=${MYIR_ENC_BACKUP_FILE}; } 2>&1)"
    if [ "$?" -ne 0 ] || echo "${msgs}" | grep -qi 'error\|invalid'; then
        myir_enc_exit_error "Couldn't save original data."
    fi
}

# call user check script
myir_run_user_check() {
    MYIR_ENC_USER_SCRIPT="/usr/sbin/encryption_allowed"
    if [ -x ${MYIR_ENC_USER_SCRIPT} ]; then
        if ! [ -O ${MYIR_ENC_USER_SCRIPT} -a -G ${MYIR_ENC_USER_SCRIPT} ]; then
            myir_enc_log "WARNING: Ignoring user check script due to invalid ownership."
        elif [ $(( 0$(stat -c %a "${MYIR_ENC_USER_SCRIPT}") & 07022 )) -ne 0 ]; then
            myir_enc_log "WARNING: Ignoring user check script due to invalid permissions."
        elif ! ${MYIR_ENC_USER_SCRIPT}; then
            myir_enc_exit_error "Encryption disabled by the user!"
        fi
    fi
}

# unmount the partition if needed ready for encryption
myir_enc_pre_unmount() {
    myir_enc_log "Unmounting partition ready to encrypt..."
    umount "${MYIR_ENC_STORAGE_MOUNTPOINT}"
}

# setup partition with dm-crypt
myir_enc_partition_setup() {
    myir_enc_log "Setting up partition with dm-crypt..."

    if ! dmsetup -v create ${MYIR_ENC_DM_DEVICE} \
                 --table "0 ${MYIR_ENC_STORAGE_NUM_BLOCKS} \
                 crypt capi:${MYIR_ENC_CIPHER_SPEC} :${MYIR_ENC_KEY_SIZE}:${MYIR_ENC_KEY_KEYRING_TYPE}:${MYIR_ENC_KEY_KEYRING_NAME} \
                 0 ${MYIR_ENC_STORAGE_LOCATION} 0 1 sector_size:512"; then
        myir_enc_exit_error "Error setting up dm-crypt partition!"
    fi

    if ! dmsetup table --showkey ${MYIR_ENC_DM_DEVICE} | grep -q ${MYIR_ENC_KEY_KEYRING_NAME}; then
        myir_enc_exit_error "Key not found in dm-crypt partition!"
    fi
}

# mount encrypted partition
myir_enc_partition_mount() {
    myir_enc_log "Mounting encrypted partition..."

    # format encrypted partition (if not formatted)
    if ! blkid /dev/mapper/"${MYIR_ENC_DM_DEVICE}"; then
        myir_enc_log "Formatting encrypted partition with ext4..."
        mkfs.ext4 -q /dev/mapper/"${MYIR_ENC_DM_DEVICE}" ${MYIR_ENC_STORAGE_MKFS_ARGS}
    fi

    # mount encrypted partition
    mkdir -p "${MYIR_ENC_STORAGE_MOUNTPOINT}"
    if ! mount -t ext4 /dev/mapper/"${MYIR_ENC_DM_DEVICE}" "${MYIR_ENC_STORAGE_MOUNTPOINT}" ${MYIR_ENC_STORAGE_MOUNT_ARGS}; then
        myir_enc_exit_error "Could not mount encrypted partition!"
    fi
}

# restore data if available
myir_enc_restore_data() {
    if [ ${MYIR_ENC_PRESERVE_DATA} -ne 1 ]; then
        myir_enc_log "Data preservation is not enabled"
        return 0
    fi

    if ! [ -f ${MYIR_ENC_BACKUP_FILE} ]; then
        myir_enc_log "No data backup to restore"
        return 0
    fi

    myir_enc_log "Restoring original content..."
    msgs="$({ { bzip2 -cd ${MYIR_ENC_BACKUP_FILE} || echo "ERROR" >&2; } | tar -C ${MYIR_ENC_STORAGE_MOUNTPOINT} -xf -; } 2>&1)"
    if [ "$?" -ne 0 ] || echo "${msgs}" | grep -qi 'error\|invalid'; then
        myir_enc_exit_error "Failed to restore backup."
    fi

    rm -rf ${MYIR_ENC_BACKUP_FILE}
}

# remove key from keyring
myir_enc_clear_keys_keyring() {
    myir_enc_log "Removing key from kernel keyring..."
    keyctl clear @s
}

# umount partition
myir_enc_partition_umount() {
    for mnt in $(lsblk /dev/mapper/"${MYIR_ENC_DM_DEVICE}" -n -o MOUNTPOINTS); do
        myir_enc_log "Unmounting dm-crypt partition from '${mnt}'..."
        umount "${mnt}"
    done
}

# remove dm-crypt partition
myir_enc_partition_remove() {
    myir_enc_log "Removing dm-crypt partition..."
    dmsetup remove ${MYIR_ENC_DM_DEVICE}
}

# mount encrypted partition
myir_enc_main_start() {
    myir_enc_cipher_configure
    if myir_enc_pre_mount; then
        myir_run_user_check
        myir_enc_backup_data
        myir_enc_pre_unmount
    fi
    myir_enc_prepare_generic
    myir_enc_prepare_${MYIR_ENC_KEY_BACKEND}
    myir_enc_key_gen_${MYIR_ENC_KEY_BACKEND}
    myir_enc_partition_setup
    myir_enc_partition_mount
    myir_enc_restore_data
}

# umount encrypted partition
myir_enc_main_stop() {
    myir_enc_partition_umount
    myir_enc_partition_remove
    myir_enc_clear_keys_keyring
}

myir_enc_main() {
    case $1 in
        start)
            myir_enc_main_start
            ;;
        stop)
            myir_enc_main_stop
            ;;
        *)
            myir_enc_exit_error "Invalid option! Please use 'start' or 'stop'."
            ;;
    esac

    myir_enc_log "Success!"
}

myir_enc_main "$1"
