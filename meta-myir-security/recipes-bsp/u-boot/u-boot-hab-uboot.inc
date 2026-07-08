# u-boot-hab-uboot.inc - HABv4 signing logic for i.MX6/7 U-Boot recipe
#
# This include file is inherited by the u-boot-imx bbappend when
# MYIR_HAB_ENABLE=1 and the machine is mx6ull-generic-bsp.
#
# Core mechanism:
#   1. After U-Boot build, extract HAB block ranges from build log
#   2. Generate CSF file from template (imx6ull_template.csf)
#   3. Run CST to create CSF binary
#   4. Concatenate CSF binary to u-boot.imx → signed binary
#   5. Repeat for SPL if SPL_BINARY is set
#   6. Generate fuse-cmds.txt from SRK fuse file + fuse template

inherit myir-hab

# Need xxd for IVT/DCD manipulation
DEPENDS += "xxd-native dtc-native"

# Need libfaketime for deterministic CSF binaries
DEPENDS += "libfaketime-native"

# Need imx-fuses-native for create_fuse_cmds.sh
DEPENDS += "imx-fuses-native"

# HAB-specific config fragment: CONFIG_IMX_HAB=y
SRC_URI:append:mx6ull-generic-bsp = " \
    ${@bb.utils.contains('MYIR_HAB_ENABLE', '1', \
        'file://mx6ull-generic-bsp/u-boot-hab.cfg', '', d)} \
"

# HAB CSF signing artifacts (i.MX6/7 only)
MYIR_HAB_CSF_ARTIFACTS ?= " \
    file://imx6_imx7_create_csf.sh \
    file://imx6ull_template.csf \
"
SRC_URI:append:mx6ull-generic-bsp = " \
    ${@bb.utils.contains('MYIR_HAB_ENABLE', '1', \
        '${MYIR_HAB_CSF_ARTIFACTS}', '', d)} \
"

# ==========================================================================
# Anonymous Python: validate SDP configs
# ==========================================================================
python __anonymous() {
    if d.getVar('MYIR_HAB_ENABLE') != '1':
        return

    scfgs = (d.getVar('MYIR_HAB_SDP_CONFIGS_INTERNAL') or "").split()
    ucfgs = (d.getVar('UBOOT_CONFIG') or "").split()
    if not ucfgs:
        for _scfg in scfgs:
            if _scfg != "*":
                bb.warnonce(
                    'UBOOT_CONFIG is not in use; MYIR_HAB_SDP_CONFIGS should '
                    'be either empty or set to "*", but it instead contains a '
                    f'configuration named "{_scfg}"; bootloader will not be '
                    'built for SDP loading.')
                break
        return

    for _scfg in scfgs:
        if _scfg == "*":
            continue
        if _scfg not in ucfgs:
            bb.warnonce(
                f'Configuration named "{_scfg}" in MYIR_HAB_SDP_CONFIGS '
                'is not listed in UBOOT_CONFIG and will be ignored; your '
                'bootloader may not be built for SDP loading.')
}

# ==========================================================================
# i.MX6/i.MX7 HABv4 signing function
#
# This function runs in the U-Boot build directory.
# It:
#   1. Determines if DCD should be included in CSF (for SDP loading)
#   2. Generates CSF from U-Boot binary using imx6_imx7_create_csf.sh
#   3. Concatenates CSF binary → signed u-boot.imx
#   4. Signs SPL if SPL_BINARY is defined
#   5. Generates fuse-cmds.txt
# ==========================================================================
myir_imx6_imx7_sign_habv4() {
    local soc="$1"
    local type="$2"
    local binary="$3"

    if [ ! -e "${MYIR_HAB_CST_BIN}" ]; then
        bbfatal "Could not find CST binary at ${MYIR_HAB_CST_BIN}. Please set MYIR_HAB_CST_DIR."
    fi

    # Binary names (default: u-boot.imx for i.MX6ULL)
    local binary_to_sign="${UBOOT_BINARY}"
    local binary_to_mkcsf="${UBOOT_BINARY}"

    # Determine if DCD should be included in CSF.
    # DCD inclusion is needed for SDP (USB serial download) boot mode
    # because the Boot ROM uses DCD for initial DDR configuration.
    local csf_inc_dcd="0"
    (
        set -f
        for _config in ${MYIR_HAB_SDP_CONFIGS_INTERNAL}; do
            if [ "${_config}" = "${type}" ] || [ "${_config}" = "*" ]; then
                exit 0
            fi
        done
        exit 1
    ) && csf_inc_dcd="1"

    if [ "${csf_inc_dcd}" = "1" ]; then
        bbdebug 1 "Generating bootloader binary with cleared DCD pointer (type='${type}')"
        if [ "$(xxd -p -l1 "${binary_to_sign}")" != "d1" ]; then
            bbfatal "File '${binary_to_sign}' does not seem to start with an IVT; aborting."
        fi
        binary_to_mkcsf="${UBOOT_BINARY}-clrdcd"
        cp -v "${binary_to_sign}" "${binary_to_mkcsf}"
        cp -v "${binary_to_sign}.log" "${binary_to_mkcsf}.log"
        # Clear DCD pointer at IVT offset 12 (0xC)
        printf '\0\0\0\0' | dd of="${binary_to_mkcsf}" bs=1 seek=12 conv=notrunc
    else
        bbdebug 1 "DCD pointer clearing has been skipped"
    fi

    # Step 1: Generate CSF from U-Boot binary
    bbdebug 1 "Generating CSF from U-Boot binary '${binary_to_mkcsf}' (type='${type}')"
    LIBFAKETIME_PATH="${STAGING_LIBDIR_NATIVE}/faketime/libfaketime.so.1" \
    MYIR_HAB_CST_SRK="${MYIR_HAB_CST_SRK}" \
    MYIR_HAB_CST_SRK_CERT="${MYIR_HAB_CST_SRK_CERT}" \
    MYIR_HAB_CST_CSF_CERT="${MYIR_HAB_CST_CSF_CERT}" \
    MYIR_HAB_CST_IMG_CERT="${MYIR_HAB_CST_IMG_CERT}" \
    MYIR_HAB_CST_BIN="${MYIR_HAB_CST_BIN}" \
    MYIR_HAB_CST_ARGS="${MYIR_HAB_CST_ARGS}" \
    CSF_INC_DCD="${csf_inc_dcd}" \
    IMXBOOT="${binary_to_mkcsf}" \
    HAB_LOG="${binary_to_mkcsf}.log" \
    ${UNPACKDIR}/imx6_imx7_create_csf.sh -m "${soc}" -c "csf_uboot"

    # Step 2: Concatenate CSF to produce signed binary
    bbdebug 1 "Concatenating CSF binary to U-Boot binary '${binary_to_sign}'"
    if [ -n "${type}" ]; then
    bbdebug 1 "Concatenating CSF binarytest11111111"
        cp  "${binary_to_sign}" "${UBOOT_BINARYNAME}-${type}.${UBOOT_SUFFIX}-unsigned"
        cat "${binary_to_sign}" "csf_uboot.bin" > "${UBOOT_BINARYNAME}-${type}.${UBOOT_SUFFIX}"
    else
        mv  "${binary_to_sign}" "${UBOOT_BINARY}-unsigned"
        cat "${UBOOT_BINARY}-unsigned" "csf_uboot.bin" > "${UBOOT_BINARY}"
    fi

    # Step 3: Sign SPL if SPL was also built
    if [ -n "${SPL_BINARY}" ] && [ -f "${SPL_BINARY}" ]; then
        bbdebug 1 "Generating CSF for the U-Boot SPL"
        LIBFAKETIME_PATH="${STAGING_LIBDIR_NATIVE}/faketime/libfaketime.so.1" \
        MYIR_HAB_CST_SRK="${MYIR_HAB_CST_SRK}" \
        MYIR_HAB_CST_SRK_CERT="${MYIR_HAB_CST_SRK_CERT}" \
        MYIR_HAB_CST_CSF_CERT="${MYIR_HAB_CST_CSF_CERT}" \
        MYIR_HAB_CST_IMG_CERT="${MYIR_HAB_CST_IMG_CERT}" \
        MYIR_HAB_CST_BIN="${MYIR_HAB_CST_BIN}" \
        MYIR_HAB_CST_ARGS="${MYIR_HAB_CST_ARGS}" \
        IMXBOOT="${SPL_BINARY}" \
        HAB_LOG="${SPL_BINARY}.log" \
        ${UNPACKDIR}/imx6_imx7_create_csf.sh -m "${soc}" -c "csf_SPL"

        bbdebug 1 "Concatenating CSF binary to the U-Boot SPL"
        mv "${SPL_BINARY}" "${SPL_BINARY}-unsigned"
        cat "${SPL_BINARY}-unsigned" "csf_SPL.bin" > "${SPL_BINARY}"
    fi

    # Step 4: Generate fuse commands
    bbdebug 1 "Generating fuse commands for ${soc}"
    ${STAGING_BINDIR_NATIVE}/myir-create-fuse-cmds \
        "${soc}" \
        "${MYIR_HAB_CST_SRK_FUSE}" \
        "${WORKDIR}/fuse-cmds.txt" \
        "${RECIPE_SYSROOT_NATIVE}${datadir}/imx-fuses"
}

# ==========================================================================
# Hook into uboot_assemble_fitimage_helper for i.MX6ULL
#
# The Yocto U-Boot build calls uboot_assemble_fitimage_helper()
# for each UBOOT_CONFIG entry. We append HAB signing after the
# standard assembly.
# ==========================================================================
uboot_assemble_fitimage_helper:append:mx6ull-generic-bsp() {
    if [ "${MYIR_HAB_ENABLE}" != "1" ]; then
        bbdebug 1 "HAB signing disabled (MYIR_HAB_ENABLE != 1), skipping"
        return 0
    fi

    type="$1"
    binary="$2"
    bbnote "HABv4 signing for IMX6ULL (config: ${type})"
    myir_imx6_imx7_sign_habv4 "IMX6ULL" "${type}" "${binary}"
}

# ==========================================================================
# Deploy fuse-cmds.txt alongside signed bootloader
# ==========================================================================
do_deploy:append:mx6ull-generic-bsp() {
    if [ "${MYIR_HAB_ENABLE}" = "1" ]; then
        if [ -e ${WORKDIR}/fuse-cmds.txt ]; then
            install -d ${DEPLOYDIR}
            install -m 0644 ${WORKDIR}/fuse-cmds.txt ${DEPLOYDIR}/
            bbnote "HAB: Deployed fuse-cmds.txt"
        fi
    fi
}
