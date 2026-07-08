#!/bin/bash
#=============================================================================
# mx6ull_sign_fit.sh - i.MX6ULL HABv4 FIT Image Signing Script
#
# Signs a FIT image for HABv4 authenticated boot on i.MX6ULL.
# The flow:
#   1. genIVT_fit.sh → generates IVT (Image Vector Table)
#   2. Pad FIT image to 0x1000 alignment, append IVT
#   3. Generate CSF from template (substitute placeholders)
#   4. Run NXP CST to sign → CSF binary
#   5. Append CSF binary → Final signed image
#
# Usage:
#     mx6ull_sign_fit.sh <unsigned_fit> <signed_output>
#
# Required Environment Variables:
#   MYIR_HABV4_CST_BIN          - Path to NXP CST binary
#   MYIR_HABV4_CSF_TEMPLATE     - Path to CSF template file
#   MYIR_HABV4_SRK_TABLE        - Path to SRK table binary
#   MYIR_HABV4_SRK_SOURCE_IDX   - SRK source index (0-based, 0..3)
#   MYIR_HABV4_CSF_KEY          - Path to CSFK certificate PEM
#   MYIR_HABV4_IMG_KEY          - Path to IMGK certificate PEM
#   MYIR_HABV4_IMG_IDX          - IMG key install slot (2 or 3)
#   MYIR_HABV4_IMAGE_LOAD_ADDR  - DDR load address (e.g. 0x80800000)
#
# Optional:
#   MYIR_HABV4_CST_ARGS         - Extra args for CST
#   GENIVT_FIT_SCRIPT           - Path to genIVT_fit.sh (default: ./genIVT_fit.sh)
#=============================================================================

set -e

readonly FILE_SCRIPT="$(basename "$0")"
readonly DIR_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# --------------------------------------------------------------------------
# Constants (must match U-Boot hab.h)
# --------------------------------------------------------------------------
readonly ALIGN_SIZE=0x1000
readonly IVT_SIZE=0x20
readonly CSF_PAD_SIZE=0x2000

error() {
    echo "***" >&2
    echo " ERROR: ${1}" >&2
    echo "***" >&2
    exit 1
}

warn() {
    echo " WARNING: ${1}" >&2
}

usage() {
    echo
    echo " Usage: ${FILE_SCRIPT} <unsigned_fit> <signed_output>"
    echo
    echo " Signs a FIT image for i.MX6ULL HABv4 authenticated boot."
    echo
    echo " Arguments:"
    echo "   unsigned_fit    Path to unsigned FIT .itb file"
    echo "   signed_output   Path for final signed image"
    echo
    echo " Environment Variables:"
    echo "   MYIR_HABV4_CST_BIN          Path to NXP CST binary"
    echo "   MYIR_HABV4_CSF_TEMPLATE     Path to CSF template"
    echo "   MYIR_HABV4_SRK_TABLE        Path to SRK table binary"
    echo "   MYIR_HABV4_SRK_SOURCE_IDX   SRK source index (0..3)"
    echo "   MYIR_HABV4_CSF_KEY          CSFK certificate PEM"
    echo "   MYIR_HABV4_IMG_KEY          IMGK certificate PEM"
    echo "   MYIR_HABV4_IMG_IDX          IMG key install slot (2..3)"
    echo "   MYIR_HABV4_IMAGE_LOAD_ADDR  DDR load address"
    echo
    echo " Example:"
    echo "   ${FILE_SCRIPT} kernel_fit.itb kernel_fit_signed.itb"
    exit 1
}

# --------------------------------------------------------------------------
# Parse arguments
# --------------------------------------------------------------------------
UNSIGNED_FIT="${1}"
SIGNED_OUTPUT="${2}"

if [ -z "${UNSIGNED_FIT}" ] || [ -z "${SIGNED_OUTPUT}" ]; then
    usage
fi

if [ ! -f "${UNSIGNED_FIT}" ]; then
    error "FIT image not found: ${UNSIGNED_FIT}"
fi

# --------------------------------------------------------------------------
# Validate required environment variables
# --------------------------------------------------------------------------
check_env() {
    local var="$1"
    local desc="$2"
    if [ -z "${!var}" ]; then
        error "${var} is not set (${desc})"
    fi
}

check_env MYIR_HABV4_CST_BIN          "NXP CST binary"
check_env MYIR_HABV4_CSF_TEMPLATE     "CSF template file"
check_env MYIR_HABV4_SRK_TABLE        "SRK table binary"
check_env MYIR_HABV4_SRK_SOURCE_IDX   "SRK source index"
check_env MYIR_HABV4_CSF_KEY          "CSFK certificate PEM"
check_env MYIR_HABV4_IMG_KEY          "IMGK certificate PEM"
check_env MYIR_HABV4_IMG_IDX          "IMG key install slot"
check_env MYIR_HABV4_IMAGE_LOAD_ADDR  "DDR load address"

if [ ! -f "${MYIR_HABV4_CST_BIN}" ]; then
    error "CST binary not found: ${MYIR_HABV4_CST_BIN}"
fi
if [ ! -f "${MYIR_HABV4_CSF_TEMPLATE}" ]; then
    error "CSF template not found: ${MYIR_HABV4_CSF_TEMPLATE}"
fi

# --------------------------------------------------------------------------
# Resolve genIVT script path
# --------------------------------------------------------------------------
GENIVT_FIT="${GENIVT_FIT_SCRIPT:-${DIR_SCRIPT}/genIVT_fit.sh}"
if [ ! -x "${GENIVT_FIT}" ]; then
    error "genIVT_fit.sh not found or not executable: ${GENIVT_FIT}"
fi

# --------------------------------------------------------------------------
# Working directory for temporary files
# --------------------------------------------------------------------------
WORKDIR="$(dirname "${SIGNED_OUTPUT}")/habv4_sign_tmp"
mkdir -p "${WORKDIR}"
# CSF temp dir preserved for debugging (not cleaned up automatically)
# trap "rm -rf ${WORKDIR}" EXIT

IVT_BIN="${WORKDIR}/ivt_fit.bin"
PADDED_IMG="${WORKDIR}/fit_padded_ivt.bin"
CSF_TXT="${WORKDIR}/csf_fit.txt"
CSF_BIN="${WORKDIR}/csf_fit.bin"

echo "========================================================================"
echo " i.MX6ULL HABv4 FIT Image Signing"
echo "========================================================================"
echo ""
echo "  Input:       ${UNSIGNED_FIT}"
echo "  Output:      ${SIGNED_OUTPUT}"
echo "  Load addr:   ${MYIR_HABV4_IMAGE_LOAD_ADDR}"
echo "  CST:         ${MYIR_HABV4_CST_BIN}"
echo "  SRK table:   ${MYIR_HABV4_SRK_TABLE}"
echo "  SRK index:   ${MYIR_HABV4_SRK_SOURCE_IDX}"
echo ""

# =========================================================================
# Step 1: Generate IVT
# =========================================================================
echo "--- Step 1: Generate IVT ---"
IVT_VARS=$("${GENIVT_FIT}" "${UNSIGNED_FIT}" "${MYIR_HABV4_IMAGE_LOAD_ADDR}" "${IVT_BIN}")
genivt_ret=$?
if [ $genivt_ret -ne 0 ]; then
    error "genIVT_fit.sh failed (exit code: $genivt_ret)"
fi

# Safely parse only the key=value lines from genIVT output.
# We explicitly source only assignment lines so that stderr text or
# accidental stdout text does not break the eval.
while IFS='=' read -r key value; do
    case "$key" in
        IVT_OFFSET|SELF_ADDR|CSF_ADDR|CSF_OFFSET|FIT_SIZE)
            printf -v "$key" '%s' "$value"
            export "$key"
            ;;
    esac
done <<EOF
$(echo "$IVT_VARS" | grep -E '^(IVT_OFFSET|SELF_ADDR|CSF_ADDR|CSF_OFFSET|FIT_SIZE)=')
EOF

# Verify all required variables are set
for var in IVT_OFFSET SELF_ADDR CSF_ADDR CSF_OFFSET FIT_SIZE; do
    if [ -z "${!var}" ]; then
        error "genIVT_fit.sh did not set ${var}"
    fi
done

echo "  FIT raw size:  ${FIT_SIZE}"
echo "  IVT offset:    ${IVT_OFFSET}"
echo "  IVT DDR addr:  ${SELF_ADDR}"
echo "  CSF DDR addr:  ${CSF_ADDR}"
echo ""

# =========================================================================
# Step 2: Build padded image (FIT + padding + IVT)
# =========================================================================
echo "--- Step 2: Build padded FIT+IVT image ---"

IVT_OFFSET_NUM=$(printf '%d' "${IVT_OFFSET}")

# Copy original FIT
cp "${UNSIGNED_FIT}" "${PADDED_IMG}"

# Pad to IVT offset (0x1000 alignment)
PAD_SIZE=$(( IVT_OFFSET_NUM - $(stat -L -c%s "${UNSIGNED_FIT}") ))
if [ "${PAD_SIZE}" -gt 0 ]; then
    dd if=/dev/zero bs=1 count="${PAD_SIZE}" >> "${PADDED_IMG}" 2>/dev/null
    echo "  Padded ${PAD_SIZE} zero bytes to 0x1000 alignment"
else
    echo "  Already aligned (no padding needed)"
fi

# Append IVT
cat "${IVT_BIN}" >> "${PADDED_IMG}"
echo "  Appended IVT (${IVT_SIZE} bytes)"
echo "  Padded image: ${PADDED_IMG} ($(stat -c%s "${PADDED_IMG}") bytes)"
echo ""

# =========================================================================
# Step 3: Generate CSF from template
# =========================================================================
echo "--- Step 3: Generate CSF ---"

# Calculate authentication length (what gets hashed):
#   raw FIT + padding + IVT (NOT including CSF area)
#   = IVT_OFFSET + IVT_SIZE (= CSF_OFFSET)
AUTH_LENGTH="${CSF_OFFSET}"
AUTH_LENGTH_HEX=$(printf '0x%08x' "${AUTH_LENGTH}")

echo "  Auth length:   ${AUTH_LENGTH_HEX} (${AUTH_LENGTH} bytes)"
echo "  Template:      ${MYIR_HABV4_CSF_TEMPLATE}"

# Build sed substitution script
# Using '|' as delimiter to avoid conflicts with path slashes
sed \
    -e "s|@@MYIR_HABV4_SRK_TABLE@@|${MYIR_HABV4_SRK_TABLE}|g" \
    -e "s|@@MYIR_HABV4_SRK_SOURCE_IDX@@|${MYIR_HABV4_SRK_SOURCE_IDX}|g" \
    -e "s|@@MYIR_HABV4_CSF_KEY@@|${MYIR_HABV4_CSF_KEY}|g" \
    -e "s|@@MYIR_HABV4_IMG_KEY@@|${MYIR_HABV4_IMG_KEY}|g" \
    -e "s|@@MYIR_HABV4_IMG_IDX@@|${MYIR_HABV4_IMG_IDX}|g" \
    -e "s|@@SIGNED_IMAGE_PATH@@|${PADDED_IMG}|g" \
    -e "s|@@IMAGE_LOAD_ADDR@@|${MYIR_HABV4_IMAGE_LOAD_ADDR}|g" \
    -e "s|@@AUTH_LENGTH@@|${AUTH_LENGTH_HEX}|g" \
    "${MYIR_HABV4_CSF_TEMPLATE}" \
    | grep -v "^[[:space:]]*#" \
    | grep -v "^$" \
    > "${CSF_TXT}"

echo "  Generated CSF: ${CSF_TXT}"
echo ""

# =========================================================================
# Step 4: Sign with CST
# =========================================================================
echo "--- Step 4: Run CST to sign ---"

if [ -n "${MYIR_HABV4_CST_ARGS}" ]; then
    echo "  CST extra args: ${MYIR_HABV4_CST_ARGS}"
fi

# CST generates CSF binary (contains signed hash + certificates)
# The --o flag specifies the output CSF binary
"${MYIR_HABV4_CST_BIN}" \
    --i "${CSF_TXT}" \
    --o "${CSF_BIN}" \
    ${MYIR_HABV4_CST_ARGS}

if [ ! -f "${CSF_BIN}" ]; then
    error "CST did not produce output: ${CSF_BIN}"
fi

CSF_SIZE=$(stat -c%s "${CSF_BIN}")
echo "  CSF binary:    ${CSF_BIN} (${CSF_SIZE} bytes)"
echo ""

# =========================================================================
# Step 5: Build final signed image
# =========================================================================
echo "--- Step 5: Build final signed image ---"

cp "${PADDED_IMG}" "${SIGNED_OUTPUT}"
cat "${CSF_BIN}" >> "${SIGNED_OUTPUT}"

SIGNED_SIZE=$(stat -c%s "${SIGNED_OUTPUT}")
echo "  Signed image:  ${SIGNED_OUTPUT} (${SIGNED_SIZE} bytes)"
echo ""

# =========================================================================
# Summary
# =========================================================================
echo "========================================================================"
echo " Signing Complete"
echo "========================================================================"
echo "  FIT size:      $(stat -L -c%s "${UNSIGNED_FIT}") bytes"
echo "  IVT offset:    ${IVT_OFFSET}"
echo "  CSF offset:    ${CSF_OFFSET}"
echo "  CSF size:      ${CSF_SIZE} bytes"
echo "  Total size:    ${SIGNED_SIZE} bytes"
echo ""
echo "  Output:        ${SIGNED_OUTPUT}"
echo ""
echo "  U-Boot bootm flow:"
echo "    load \${loaddev} \${fitconf} ${MYIR_HABV4_IMAGE_LOAD_ADDR} ${SIGNED_OUTPUT##*/}"
echo "    bootm ${MYIR_HABV4_IMAGE_LOAD_ADDR}"
echo ""
echo "  Verify at U-Boot prompt:"
echo "    hab_auth_img ${MYIR_HABV4_IMAGE_LOAD_ADDR} \$(printf '%d' ${AUTH_LENGTH_HEX}) \$(printf '%d' ${IVT_OFFSET})"
echo "========================================================================"
