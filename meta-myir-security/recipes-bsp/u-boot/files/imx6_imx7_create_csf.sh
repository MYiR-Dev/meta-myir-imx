#!/bin/bash
# ============================================================================
# imx6_imx7_create_csf.sh - Generate HABv4 CSF for i.MX6/i.MX7
#
# Adapted for MYIR meta-myir-security layer.
#
# This script:
#   1. Reads the CSF template file for the target SoC
#   2. Substitutes variable placeholders (@@VAR@@) with actual values
#   3. Handles CA flag vs non-CA (SRK install vs CSFK+IMGK install)
#   4. Extracts HAB/DCD block ranges from U-Boot build log
#   5. Runs NXP CST to generate the signed CSF binary
#
# Required Environment Variables:
#   MYIR_HAB_CST_BIN       Path to NXP CST Binary
#   MYIR_HAB_CST_SRK       Path to SRK Table
#   MYIR_HAB_CST_SRK_CERT  Path to SRK public key certificate
#   MYIR_HAB_CST_CSF_CERT  Path to CSF public key cert (if CA=1)
#   MYIR_HAB_CST_IMG_CERT  Path to IMG public key cert (if CA=1)
#   MYIR_HAB_CST_ARGS      Additional CST arguments (optional)
#   IMXBOOT                Path to unsigned U-Boot binary
#   HAB_LOG                Path to U-Boot build log with HAB info
#   CSF_INC_DCD            Include DCD blocks in CSF (set to 1 for SDP)
#   LIBFAKETIME_PATH       Path to libfaketime (optional, for reproducible builds)
# ============================================================================

[ "${XTRACE}" = "1" ] && set -x
set -e

readonly FILE_SCRIPT="$(basename "$0")"
readonly DIR_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

MACHINE=""
CSF=""
TEMPLATE_FILE=""
LIBFAKETIME_PATH="${LIBFAKETIME_PATH}"
CSF_INC_DCD="${CSF_INC_DCD:-0}"

# Timestamp for libfaketime (deterministic CSF binaries)
# Default: November 6, 2024 (12:00 PM UTC)
FAKETIME=${FAKETIME:-1730894400}

error() {
    echo "***" >&2
    echo " ERROR: ${1}" >&2
    echo "***" >&2
    exit 1
}

help() {
    echo
    echo " Usage: ${DIR_SCRIPT}/${FILE_SCRIPT} <options>"
    echo
    echo " Required Environment Variables:"
    echo
    echo "    MYIR_HAB_CST_BIN       Path to NXP CST Binary"
    echo "    MYIR_HAB_CST_SRK       Path to SRK Table"
    echo "    MYIR_HAB_CST_SRK_CERT  Path to SRK public key certificate"
    echo "    MYIR_HAB_CST_CSF_CERT  Path to CSF public key cert (needed if CA flag set)"
    echo "    MYIR_HAB_CST_IMG_CERT  Path to IMG public key cert (needed if CA flag set)"
    echo "    IMXBOOT                Path to unsigned u-boot image"
    echo "    HAB_LOG                Path to u-boot build log with HAB info"
    echo
    echo " Optional Environment Variables:"
    echo
    echo "    MYIR_HAB_CST_ARGS      Additional parameters for CST tool"
    echo "    CSF_INC_DCD            Include DCD blocks (1 for SDP, default: 0)"
    echo "    LIBFAKETIME_PATH       Path to libfaketime library"
    echo
    echo " Required Arguments:"
    echo "    -m --machine           Target SoC (IMX6, IMX7, IMX6ULL)"
    echo "    -c --csf               CSF basename (output: <basename>.{csf,bin,log})"
    echo
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                help
            ;;
            -m|--machine)
                MACHINE="$2"
                shift; shift
            ;;
            -c|--csf)
                CSF="$2"
                shift; shift
            ;;
            *)
                echo "Unknown option: $1"
                help
            ;;
        esac
    done
}

check_fileref() {
    local file="${1?file name expected}"
    local varname="${2?variable name expected}"
    if [ -z "${file}" ]; then
        error "Please set environment variable '${varname}'"
    fi
    if [ ! -f "${file}" ]; then
        error "Could not find '${file}' referenced by variable ${varname} (CWD=$(pwd))"
    fi
    echo "Verified ${varname}=${file}"
}

validate_environ() {
    check_fileref "${MYIR_HAB_CST_BIN}" "MYIR_HAB_CST_BIN"
    check_fileref "${MYIR_HAB_CST_SRK}" "MYIR_HAB_CST_SRK"
    check_fileref "${MYIR_HAB_CST_SRK_CERT}" "MYIR_HAB_CST_SRK_CERT"
    if [ "${MYIR_HAB_CST_SRK_CERT##*_ca_}" = "crt.pem" ]; then
        check_fileref "${MYIR_HAB_CST_CSF_CERT}" "MYIR_HAB_CST_CSF_CERT"
        check_fileref "${MYIR_HAB_CST_IMG_CERT}" "MYIR_HAB_CST_IMG_CERT"
    fi
    check_fileref "${IMXBOOT}" "IMXBOOT"
    check_fileref "${HAB_LOG}" "HAB_LOG"
}

set_template_file() {
    case ${MACHINE} in
        "IMX6ULL")
            TEMPLATE_FILE="imx6ull_template.csf"
            ;;
        "IMX7")
            TEMPLATE_FILE="imx7_template.csf"
            ;;
        "IMX6")
            TEMPLATE_FILE="imx6_template.csf"
            ;;
        *)
            echo "Invalid SoC!"
            return 1
            ;;
    esac
}

generate_csf() {
    local image_csf="${CSF}.csf"

    # Copy template file
    echo "Creating CSF file: ${image_csf}"
    cp "${DIR_SCRIPT}/${TEMPLATE_FILE}" "${image_csf}"

    # Determine key index from certificate file name
    local kidx
    kidx=${MYIR_HAB_CST_SRK_CERT##*/}
    kidx=${kidx##SRK}
    kidx=${kidx%%_*}
    if [ "${#kidx}" != 1 ]; then
        echo "Certificate file name (from MYIR_HAB_CST_SRK_CERT) does" \
             "not match expected pattern - could not determine SRK key index."
        exit 1
    fi

    if [ "${kidx}" -ge 1 ] && [ "${kidx}" -le 4 ]; then
        echo "Using SRK${kidx} for signing."
    else
        echo "Bad SRK key index '${kidx}' (inferred from MYIR_HAB_CST_SRK_CERT) - aborting."
        exit 1
    fi
    kidx=$((kidx - 1))

    # Determine if CA flag was set
    local ca
    if [ "${MYIR_HAB_CST_SRK_CERT##*_ca_}" = "crt.pem" ]; then
        ca=1
    elif [ "${MYIR_HAB_CST_SRK_CERT##*_usr_}" = "crt.pem" ]; then
        ca=0
    else
        echo "Certificate file name (from MYIR_HAB_CST_SRK_CERT)" \
             "does not match expected pattern - could not determine if CA flag is set."
        exit 1
    fi

    # Update "Install SRK" section
    sed -i "s|@@CST_SRK@@|${MYIR_HAB_CST_SRK}|g" "${image_csf}"
    sed -i "s|@@CST_KIDX@@|${kidx}|g" "${image_csf}"

    if [ "$ca" = 1 ]; then
        # Keep "Install CSFK" and update
        sed -i "/#+START_INSTALL_CSFK_BLOCK/d; /#+END_INSTALL_CSFK_BLOCK/d" "${image_csf}"
        sed -i "s|@@CST_CSF_CERT@@|${MYIR_HAB_CST_CSF_CERT}|g" "${image_csf}"
        # Delete "Install NOCAK"
        sed -i "/#+START_INSTALL_NOCAK_BLOCK/,/#+END_INSTALL_NOCAK_BLOCK/d" "${image_csf}"
    else
        # Delete "Install CSFK"
        sed -i "/#+START_INSTALL_CSFK_BLOCK/,/#+END_INSTALL_CSFK_BLOCK/d" "${image_csf}"
        # Keep "Install NOCAK" and update
        sed -i "/#+START_INSTALL_NOCAK_BLOCK/d; /#+END_INSTALL_NOCAK_BLOCK/d" "${image_csf}"
        sed -i "s|@@CST_SRK_CERT@@|${MYIR_HAB_CST_SRK_CERT}|g" "${image_csf}"
    fi

    if [ "$ca" = 1 ]; then
        # Keep "Install Key" (IMGK) and update
        sed -i "/#+START_INSTALL_KEY_BLOCK/d; /#+END_INSTALL_KEY_BLOCK/d" "${image_csf}"
        sed -i "s|@@CST_IMG_CERT@@|${MYIR_HAB_CST_IMG_CERT}|g" "${image_csf}"
        # Verification index = 2 (IMGK slot in HAB key store)
        sed -i "s|@@CST_AUTH_KIDX@@|2|g" "${image_csf}"
    else
        # Delete "Install Key"
        sed -i "/#+START_INSTALL_KEY_BLOCK/,/#+END_INSTALL_KEY_BLOCK/d" "${image_csf}"
        # Verification index = 0 (SRK slot in HAB key store)
        sed -i "s|@@CST_AUTH_KIDX@@|0|g" "${image_csf}"
    fi

    # Delete placeholder 'Blocks =' line from template
    sed -i "/Blocks = /d" "${image_csf}"

    # Extract actual HAB block ranges from U-Boot build log
    # Format: "HAB Blocks: <start> <offset> <length>"
    if grep -q "HAB Blocks" "${HAB_LOG}"; then
        echo "    Blocks = $(grep 'HAB Blocks' "${HAB_LOG}" | awk '{print $3, $4, $5}') \"${IMXBOOT}\"" >> "${image_csf}"
    else
        error "Could not find 'HAB Blocks' section in '${HAB_LOG}'; aborting."
    fi

    # If DCD inclusion is requested (for SDP loading)
    if [ "${CSF_INC_DCD}" = "1" ]; then
        if grep -q "DCD Blocks" "${HAB_LOG}"; then
            # Add comma to last line and append DCD blocks
            sed -e '$ s/$/, \\/' -i "${image_csf}"
            echo "             $(grep 'DCD Blocks' "${HAB_LOG}" | awk '{print $3, $4, $5}') \"${IMXBOOT}\"" >> "${image_csf}"
        else
            error "Could not find 'DCD Blocks' section in '${HAB_LOG}'; aborting."
        fi
    fi

    # Generate CSF binary with CST
    echo "Running CST to generate signed CSF binary..."
    if ! env ${LIBFAKETIME_PATH+LD_PRELOAD="${LIBFAKETIME_PATH}"
                                FAKETIME_FMT="%s"
                                FAKETIME="@${FAKETIME}"} \
             "${MYIR_HAB_CST_BIN}" ${MYIR_HAB_CST_ARGS} -i "${image_csf}" -o "${CSF}.bin" > "${CSF}.log" 2>&1
    then
        echo "CST execution log:" >&2
        cat "${CSF}.log" | sed 's@^@|@' >&2
        error "CST failed to execute; please check logs."
    fi
    echo "CSF binary generated: ${CSF}.bin"
    cat "${CSF}.log"
}

parse_args "$@"

# Print command for Yocto logs
echo "$0" "$@"

# Verify required arguments
[ -n "${MACHINE}" ] || error "machine name not specified (use -m IMX6ULL)"
[ -n "${CSF}" ]     || error "CSF basename not specified (use -c csf_uboot)"

set_template_file
validate_environ
generate_csf
