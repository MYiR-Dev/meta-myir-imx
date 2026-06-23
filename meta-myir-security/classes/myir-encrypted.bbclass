# myir-encrypted.bbclass
# DM-Crypt Encrypted Data Partition for MYIR i.MX95 Platforms
#
# This class enables dm-crypt encryption of a dedicated data partition,
# with hardware-backed key management via OP-TEE (i.MX95 uses ELE,
# not CAAM — CAAM does not exist on i.MX95).
#
# Chain of trust with dm-crypt:
#   AHAB(boot container) -> FIT verified boot(kernel+initramfs) -> dm-verity(rootfs)
#                                                            -> dm-crypt(data partition)
#
# Usage:
#   Add to conf/local.conf:
#     INHERIT += "myir-encrypted"
#     MYIR_ENC_STORAGE_LOCATION = "/dev/mmcblk0p4"
#
# Dependencies:
#   - Kernel with dm-crypt, OP-TEE (TEE), trusted keys support
#   - myir-enc-handler package (auto-installed)
#
DISTROOVERRIDES .= ":myir-encrypted"

# --------------------------------------------------------------------------
# Encryption key backend
#
# Available options:
#   tee       -> use OP-TEE/TEE (recommended for i.MX95, uses ELE)
#   caam      -> use CAAM (i.MX8 only — i.MX95 does NOT have CAAM!)
#   cleartext -> key stored in clear text (FOR TESTING ONLY)
#   tpm       -> use TPM (requires hardware TPM or fTPM)
# --------------------------------------------------------------------------
MYIR_ENC_KEY_BACKEND ?= "caam"
MYIR_ENC_KEY_BACKEND:mx95-generic-bsp ?= "tee"

# WARNING: changing this on an already-encrypted device will make data unrecoverable.
MYIR_ENC_CIPHER ?= "aes-xts"

# Encryption key blob location: filesystem | partition
MYIR_ENC_KEY_LOCATION ?= "filesystem"
MYIR_ENC_KEY_DIR ?= "/var/local/private/.keys"
MYIR_ENC_KEY_FILE ?= "myir-enc-key.blob"

# Partition to be encrypted (MUST be set by the user)
MYIR_ENC_STORAGE_TYPE ?= "partition"
MYIR_ENC_STORAGE_LOCATION ?= ""
MYIR_ENC_STORAGE_RESERVE ?= "0"
MYIR_ENC_STORAGE_MOUNTPOINT ?= "/run/encdata"
MYIR_ENC_STORAGE_MKFS_ARGS ?= ""
MYIR_ENC_STORAGE_MOUNT_ARGS ?= ""

# Preserve existing data on the partition before encryption
MYIR_ENC_PRESERVE_DATA ?= "0"
MYIR_ENC_BACKUP_STORAGE_PCT ?= "30"

# Auto-install the encryption handler package
IMAGE_INSTALL:append = " myir-enc-handler"

# --------------------------------------------------------------------------
# Validate encryption parameters at parse time
# --------------------------------------------------------------------------
addhandler validate_myir_enc_parameters
validate_myir_enc_parameters[eventmask] = "bb.event.SanityCheck"
python validate_myir_enc_parameters() {
    key_backend = e.data.getVar("MYIR_ENC_KEY_BACKEND")
    if key_backend == "":
        bb.fatal("Please set key backend provider via MYIR_ENC_KEY_BACKEND.")
    supported_key_backends = ["cleartext", "caam", "tpm", "tee"]
    if key_backend not in supported_key_backends:
        bb.fatal("'%s' is invalid. Please set a valid key backend via MYIR_ENC_KEY_BACKEND." % key_backend)

    storage_location = e.data.getVar("MYIR_ENC_STORAGE_LOCATION")
    if storage_location == "":
        bb.fatal("Please set storage to be encrypted via MYIR_ENC_STORAGE_LOCATION.")

    cipher = e.data.getVar("MYIR_ENC_CIPHER")
    supported_ciphers = ["aes-cbc", "aes-xts"]
    if cipher not in supported_ciphers:
        bb.fatal("'%s' is invalid. Supported ciphers: %s" % (cipher, ", ".join(supported_ciphers)))
}

# --------------------------------------------------------------------------
# WIC file selection when encryption is active
#
# Uses a 4-partition layout: imx-boot + /boot + dm-verity-rootfs + data
# The data partition (p4) is formatted and encrypted at first boot
# by myir-enc-handler.
# --------------------------------------------------------------------------
WKS_FILE:myir-encrypted = "myd-jmx95-15x15-lpddr5-enc.wks.in"
