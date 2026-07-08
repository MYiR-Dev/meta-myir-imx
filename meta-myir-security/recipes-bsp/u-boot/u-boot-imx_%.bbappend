# Secure boot config fragments for MYIR i.MX95
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# AHAB boot support (i.MX95 only)
SRC_URI:append:mx9-generic-bsp = " \
   ${@bb.utils.contains('MYIR_AHAB_ENABLE', '1', \
        'file://mx9-generic-bsp/u-boot-hab.cfg', '', d)} \
"

# fitImage boot + FIT signature verification for i.MX95
SRC_URI:append = " \
    ${@bb.utils.contains("ENABLE_FITIMAGE_SIGN", "1", \
        "file://fitimage-boot.cfg", "", d)} \
"

# Secure boot combined config (AHAB: i.MX95)
SRC_URI:append = " \
    ${@bb.utils.contains('MYIR_AHAB_ENABLE', '1', \
        'file://u-boot-secure-boot.cfg', '', d)} \
"
# Secure boot combined config (HABv4: i.MX6ULL)
SRC_URI:append = " \
    ${@bb.utils.contains('MYIR_HAB_ENABLE', '1', \
        'file://u-boot-secure-boot.cfg', '', d)} \
"

# FIT HABv4 authentication config (i.MX6/7)
# Enables CONFIG_FIT + CONFIG_FIT_SIGNATURE for the FIT HAB
# authentication path in cmd/bootm.c (authenticate_image on FIT blob)
SRC_URI:append:mx6ull-generic-bsp = " \
    ${@bb.utils.contains('MYIR_HAB_ENABLE', '1', \
        'file://u-boot-mx6ull-hab.cfg', '', d)} \
"

# Non-FIT HAB config (i.MX6ULL only --- LEGACY_IMAGE_FORMAT + IVT_OFFSET)
# These settings are ONLY safe for non-FIT mode. In FIT mode,
# CONFIG_SYS_LOAD_ADDR=0x82000000 matches the FIT load address,
# causing authenticate_image() to use a fixed 16MB IVT offset
# instead of ALIGN(fit_size, 0x1000) -> bad IVT magic.
SRC_URI:append:mx6ull-generic-bsp = " \
    ${@bb.utils.contains('MYIR_HAB_TEE_MODE', 'nonfit', \
        'file://u-boot-mx6ull-hab-nonfit.cfg', '', d)} \
"


# FIT signature verification (HABv4: i.MX6ULL)
# Handled by u-boot-fit-signature.inc (conditionally included below)

# Hardening --- command whitelist, bootm/CLI/bootargs protection (AHAB: i.MX95)
SRC_URI:append = " \
    ${@bb.utils.contains('MYIR_AHAB_ENABLE', '1', \
        'file://u-boot-harden.cfg', '', d)} \
"
# Hardening --- command whitelist, bootm/CLI/bootargs protection (HABv4: i.MX6ULL)
SRC_URI:append = " \
    ${@bb.utils.contains('MYIR_HAB_ENABLE', '1', \
        'file://u-boot-harden.cfg', '', d)} \
"

# Disable legacy image format when secure boot is enabled (AHAB: i.MX95)
SRC_URI:append = " \
    ${@bb.utils.contains('MYIR_AHAB_ENABLE', '1', \
        'file://disable-bootmeths.cfg', '', d)} \
"
# Disable legacy image format when secure boot is enabled (HABv4: i.MX6ULL)
SRC_URI:append = " \
    ${@bb.utils.contains('MYIR_HAB_ENABLE', '1', \
        'file://disable-bootmeths.cfg', '', d)} \
"

# ==========================================================================
# FIT signature support for HABv4 (i.MX6ULL)
#
# Conditionally includes u-boot-fit-signature.inc which enables
# CONFIG_FIT_SIGNATURE=y in U-Boot and adds NXP-specific concat_dtb
# hooks for u-boot.imx format.
#
# Guard: only loaded when mx6ull-generic-bsp + MYIR_FIT_ENABLE=1.
# Zero impact on i.MX95 (mx9-generic-bsp) builds.
# ==========================================================================
include ${@bb.utils.contains("MYIR_FIT_ENABLE", "1", "u-boot-fit-signature.inc", "no-fit.inc", d) if "mx6ull-generic-bsp" in d.getVar("OVERRIDES").split(":") else "no-fit.inc"}

# ==========================================================================
# HABv4 signing support (i.MX6ULL only)
# When MYIR_HAB_ENABLE=1 and SOC family is mx6ull, the full HAB signing
# logic (CSF generation, CST invocation, fuse commands) is pulled in.
# When not enabled, an empty stub is included instead.
# All HAB additions are guarded by mx6ull-generic-bsp override, ensuring
# zero impact on i.MX95 (mx9-generic-bsp) builds.
# ==========================================================================
MYIR_UBOOT_HAB_INC = "u-boot-hab-uboot-empty.inc"
MYIR_UBOOT_HAB_INC:mx6ull-generic-bsp = "${@bb.utils.contains('MYIR_HAB_ENABLE', '1', 'u-boot-hab-uboot.inc', 'u-boot-hab-uboot-empty.inc', d)}"
include ${MYIR_UBOOT_HAB_INC}

# ==========================================================================
# HAB+TEE Boot config fragments (i.MX6ULL only)
#
# Conditionally includes u-boot-hab-tee.inc which adds the appropriate
# BOOTCOMMAND config fragment based on MYIR_HAB_TEE_MODE:
#   MYIR_HAB_TEE_MODE=nonfit -> hab-tee-nonfit-boot.cfg (run mmchabboot)
#   MYIR_HAB_TEE_MODE=fit    -> hab-tee-fit-boot.cfg   (future, Scheme 2)
#
# Guard: only loaded when mx6ull-generic-bsp + MYIR_HAB_TEE_MODE is set.
# Uses no-hab-tee.inc (empty stub) when MYIR_HAB_TEE_MODE is empty or the
# machine is not mx6ull-generic-bsp.
# ==========================================================================
MYIR_UBOOT_HAB_TEE_INC = "no-hab-tee.inc"
MYIR_UBOOT_HAB_TEE_INC:mx6ull-generic-bsp = "${@bb.utils.contains_any('MYIR_HAB_TEE_MODE', 'nonfit fit', 'u-boot-hab-tee.inc', 'no-hab-tee.inc', d)}"
include ${MYIR_UBOOT_HAB_TEE_INC}

# ==========================================================================
# i.MX6ULL WIC env coverage: Generate u-boot-env.bin from initial-env text.
# mkenvimage equivalent (CRC32 + padded binary, 8KB).
# WKS writes it to MMC at --offset 0xE0000 (primary) and 0xE2000 (redundant).
#
# Eliminates "Starting kernel..." hang caused by stale env data from previous
# flash surviving in the gap between u-boot rawcopy (~0xBEC00) and the first
# WIC partition (4MB).
#
# Support both multi-config (UBOOT_CONFIG) and single-config modes.
# ==========================================================================
do_deploy:append:mx6ull-generic-bsp() {
    ENVSIZE=8192

    if [ -n "${UBOOT_CONFIG}" ]; then
        for type in ${UBOOT_CONFIG}; do
            INITENV="${DEPLOYDIR}/${UBOOT_INITIAL_ENV}-${type}"
            ENVBIN="${DEPLOYDIR}/u-boot-env.bin"
            if [ -f "$INITENV" ]; then
                bbnote "uboot-env-bin: Generating $ENVBIN from $INITENV (size=$ENVSIZE)"

                python3 -c "
import struct, zlib, sys

size = int(sys.argv[1])
with open(sys.argv[2], 'r') as f:
    data = f.read().rstrip('\\n').replace('\\n', '\\0') + '\\0'

# Pad to env size (minus 4 bytes for CRC32 header)
flags = 0x01  # active flag for redundant env
padded = data.ljust(size - 5, '\0')
# U-Boot env format: bytes[0:4] = CRC32(data[4:]) in LE
crc = zlib.crc32(padded.encode()) & 0xffffffff
with open(sys.argv[3], 'wb') as f:
    f.write(struct.pack('<I', crc))
    f.write(bytes([flags]))  # 1-byte active flag
    f.write(padded.encode())
" $ENVSIZE "$INITENV" "$ENVBIN"

                bbnote "uboot-env-bin: $ENVBIN generated ($(stat -L -c%s $ENVBIN) bytes)"
                break
            fi
        done
        if [ ! -f "${DEPLOYDIR}/u-boot-env.bin" ]; then
            bbwarn "uboot-env-bin: no initial-env found for types ${UBOOT_CONFIG}, skipping"
        fi
    else
        INITENV="${DEPLOYDIR}/${UBOOT_INITIAL_ENV}"
        ENVBIN="${DEPLOYDIR}/u-boot-env.bin"
        if [ -f "$INITENV" ]; then
            bbnote "uboot-env-bin: Generating $ENVBIN from $INITENV (size=$ENVSIZE)"

            python3 -c "
import struct, zlib, sys

size = int(sys.argv[1])
with open(sys.argv[2], 'r') as f:
    data = f.read().rstrip('\\n').replace('\\n', '\\0') + '\\0'

# Pad to env size (minus 4 bytes for CRC32 header)
flags = 0x01  # active flag for redundant env
padded = data.ljust(size - 5, '\0')
# U-Boot env format: bytes[0:4] = CRC32(data[4:]) in LE
crc = zlib.crc32(padded.encode()) & 0xffffffff
with open(sys.argv[3], 'wb') as f:
    f.write(struct.pack('<I', crc))
    f.write(bytes([flags]))  # 1-byte active flag
    f.write(padded.encode())
" $ENVSIZE "$INITENV" "$ENVBIN"

            bbnote "uboot-env-bin: $ENVBIN generated ($(stat -L -c%s $ENVBIN) bytes)"
        else
            bbwarn "uboot-env-bin: $INITENV not found, skipping env binary generation"
        fi
    fi
}
