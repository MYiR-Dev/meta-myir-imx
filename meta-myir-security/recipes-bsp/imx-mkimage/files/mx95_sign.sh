#!/bin/bash
#=============================================================================
# mx95_sign.sh - i.MX95 AHAB Container Signing Script
#
# Based on the NXP AHAB container signing pattern.  
# Generates an AHAB CSF file from template and signs the boot container
# image using NXP's CST (Code Signing Tool).
#
# For i.MX95, two containers need to be signed:
#   Container #0: u-boot-atf-container.img (ATF + U-Boot proper + OPTEE)
#   Container #1: flash.bin (boot container with SPL + DDR FW + Container #0)
#
# Required Environment Variables:
#   MYIR_AHAB_CST_BIN       - Path to NXP CST binary
#   MYIR_AHAB_CST_SRK       - Path to SRK table binary
#   MYIR_AHAB_CST_SRK_CERT  - Path to SRK certificate PEM
#   MYIR_AHAB_CSF_TEMPLATE  - Path to CSF template file
#   UNSIGNED_IMAGE           - Path to unsigned container image
#   LOG_MKIMAGE              - Path to mkimage log (for offset extraction)
#   MYIR_AHAB_SRK_SOURCE_IDX - SRK source index (0-based, 0..3)
#
# Optional:
#   MYIR_AHAB_CST_ARGS      - Extra args for CST
#   MYIR_AHAB_CST_SGK_CERT  - SGK certificate (only if SGK is supported)
#   MYIR_AHAB_USE_SGK       - Set to 1 to enable SGK
#=============================================================================

set -e

readonly FILE_SCRIPT="$(basename "$0")"
readonly DIR_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

error() {
    echo "***" >&2
    echo " ERROR: ${1}" >&2
    echo "***" >&2
    exit 1
}

help() {
    echo
    echo " Usage: ${FILE_SCRIPT} <target>"
    echo
    echo " Required Environment Variables:/
