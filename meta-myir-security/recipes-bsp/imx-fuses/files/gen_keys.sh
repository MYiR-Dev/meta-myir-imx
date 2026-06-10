#!/bin/bash
#=============================================================================
# gen_keys.sh - Generate AHAB Signing Keys for i.MX95 (CST 4.0.1+)
#
# This script generates the Super Root Key (SRK) pairs and certificate
# chain required for i.MX95 AHAB secure boot using NXP's CST tool v4.0.1.
#
# Correct flow for CST 4.x:
#   1. ahab_pki_tree binary -> generates CA + SRK keys and certificates
#   2. srktool --ahab_ver 2 -> generates SRK table from certificates
#
# Prerequisites:
#   - NXP CST tool v4.0.1+ installed
#
# Output files:
#   crts/SRK{1..4}_sha384_secp384r1_v3_usr_crt.pem  - SRK certificates
#   crts/SRK_1_2_3_4_tables.bin                      - SRK table (fused to SoC)
#   crts/SRK_1_2_3_4_fuses.bin                       - SRK fuse values
#   keys/SRK{1..4}_sha384_secp384r1_v3_usr_key.pem  - SRK private keys
#   keys/key_pass.txt                               - Key password
#
# Usage:
#   ./gen_keys.sh
#
# After generation:
#   1. BACK UP the keys/ directory (private keys!)
#   2. Burn SRK fuses using gen_fuse_cmds.sh
#   3. Build Yocto with MYIR_AHAB_ENABLE = "1"
#=============================================================================

set -e

# ==========================================================================
# Configuration - auto-detect paths from script location
# ==========================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# SCRIPT_DIR = .../secure_yocto/sources/meta-myir-security/recipes-bsp/imx-fuses/files
# CST_DIR needs: .../secure_yocto/keys/cst
# So go up 5 levels from files/ to secure_yocto/
# files -> imx-fuses -> recipes-bsp -> meta-myir-security -> sources -> secure_yocto
LAYER_DIR="$( cd "$SCRIPT_DIR/../../../../.." >/dev/null 2>&1 && pwd )"
CST_DIR="${CST_DIR:-${LAYER_DIR}/keys/cst}"

PKI_TREE="${CST_DIR}/linux64/bin/ahab_pki_tree"
SRKTOOL="${CST_DIR}/linux64/bin/srktool"

# ==========================================================================
# Key parameters (for i.MX95 AHAB) - matches myir-ahab.bbclass defaults
# ==========================================================================
KEY_TYPE="ecc"              # Elliptic Curve Cryptography
KEY_CURVE="secp384r1"         # NIST P-384 curve (cert naming: secp384r1 — matches bbclass)
PKI_KEY_LEN="p384"           # Curve name for ahab_pki_tree -kl arg (p384, not secp384r1)
DIGEST="sha384"              # SHA-384 message digest
SIGN_DIGEST="sha384"         # Signature digest (must match SRK table settings)
AHAB_VER=2                    # AHAB version (2 = hybrid, i.MX95 B0+)
SRK_COUNT=4                   # Number of SRKs (1-4)
SRK_CA=n                      # n = non-CA (usr cert) -- i.MX95 ROM does NOT support SGK
DURATION=10                   # Certificate validity (years)
FUSE_FORMAT=1                 # Fuse format: 1 = 32 fuses per word

echo "============================================"
echo "i.MX95 AHAB Key Generation (CST 4.0.1)"
echo "============================================"
echo "Key Type:    ${KEY_TYPE}"
echo "Curve:       ${KEY_CURVE}"
echo "Digest:      ${DIGEST}"
echo "Sign Digest: ${SIGN_DIGEST}"
echo "AHAB Ver:    ${AHAB_VER}"
echo "SRK Count:   ${SRK_COUNT}"
echo "SRK CA:      ${SRK_CA} (non-CA = no SGK for i.MX95)"
echo "Duration:    ${DURATION} years"
echo "CST Dir:     ${CST_DIR}"
echo "============================================"

# Verify CST tools exist
if [ ! -x "${PKI_TREE}" ]; then
    echo "ERROR: ahab_pki_tree not found at ${PKI_TREE}"
    echo "Please download NXP CST from:"
    echo "  https://www.nxp.com/webapp/sps/download/license.jsp?colCode=IMX_CST_TOOL_NEW"
    exit 1
fi

if [ ! -x "${SRKTOOL}" ]; then
    echo "ERROR: srktool not found at ${SRKTOOL}"
    exit 1
fi

# Create required directories
mkdir -p "${CST_DIR}/keys"
mkdir -p "${CST_DIR}/crts"
mkdir -p "${CST_DIR}/ca"

echo ""
echo "[1/3] Preparing key passphrase and serial files..."

# Create serial number file
echo "12345678" > "${CST_DIR}/keys/serial"

# Create key passphrase file (ahab_pki_tree reads this)
# Format: password repeated on two lines
cat > "${CST_DIR}/keys/key_pass.txt" << EOF
myir_ahab_secure_boot
myir_ahab_secure_boot
EOF
echo "  Key passphrase: myir_ahab_secure_boot"
echo "  WARNING: For production, use a strong, unique passphrase!"

echo ""
echo "[2/3] Generating PKI tree (CA + SRK keys and certificates)..."
echo "  Command: ahab_pki_tree -existing-ca n -kt ${KEY_TYPE} -kl ${PKI_KEY_LEN}"
echo "           -da ${DIGEST} -duration ${DURATION} -srk-ca ${SRK_CA}"

# Run ahab_pki_tree from CST_DIR (it creates keys/ and crts/ relative to CWD)
cd "${CST_DIR}"
"${PKI_TREE}" \
    -existing-ca n \
    -kt "${KEY_TYPE}" \
    -kl "${PKI_KEY_LEN}" \
    -da "${DIGEST}" \
    -duration "${DURATION}" \
    -srk-ca "${SRK_CA}"

echo ""
echo "[3/3] Generating SRK table from certificates..."
echo "  Command: srktool --ahab_ver ${AHAB_VER} --sign_digest ${SIGN_DIGEST}"

# Build comma-separated certificate list
SRK_CERTS=""
for i in $(seq 1 ${SRK_COUNT}); do
    cert_name="SRK${i}_${DIGEST}_${KEY_CURVE}_v3_usr_crt.pem"
    cert_path="crts/${cert_name}"
    if [ ! -f "${CST_DIR}/${cert_path}" ]; then
        echo "ERROR: SRK certificate not generated: ${cert_name}"
        echo "  Available certs:"
        ls -la "${CST_DIR}/crts/"
        exit 1
    fi
    if [ -z "${SRK_CERTS}" ]; then
        SRK_CERTS="${cert_path}"
    else
        SRK_CERTS="${SRK_CERTS},${cert_path}"
    fi
done

echo "  Certificates: ${SRK_CERTS}"

# Generate SRK table and fuse file
# CRITICAL: --ahab_ver 2 is REQUIRED. Missing it produces HAB4 format (2112 bytes)
# which will fail with "Super Root Key table is invalid" during CST signing.
"${SRKTOOL}" \
    --ahab_ver "${AHAB_VER}" \
    --sign_digest "${SIGN_DIGEST}" \
    -f "${FUSE_FORMAT}" \
    -t "${CST_DIR}/crts/SRK_1_2_3_4_tables.bin" \
    -e "${CST_DIR}/crts/SRK_1_2_3_4_fuses.bin" \
    -c "${SRK_CERTS}"

echo ""
echo "============================================"
echo "Verifying generated files..."
echo "============================================"

check_file() {
    if [ -f "$1" ]; then
        size=$(stat -c%s "$1" 2>/dev/null || stat -f%z "$1" 2>/dev/null)
        echo "  [OK] $2 (${size} bytes)"
    else
        echo "  [FAIL] $2 not found: $1"
        exit 1
    fi
}

check_file "${CST_DIR}/crts/SRK_1_2_3_4_tables.bin" "SRK table"
check_file "${CST_DIR}/crts/SRK_1_2_3_4_fuses.bin"  "SRK fuse values"

# Verify SRK table format
# Correct AHAB v2: magic = 0047 035a, size ~839 bytes
# Wrong HAB4:       magic = d740 0842, size ~2112 bytes
echo ""
echo "  SRK table verification:"
xxd "${CST_DIR}/crts/SRK_1_2_3_4_tables.bin" | head -1
echo "  Expected: 0047 035a (AHAB v2) -- NOT d740 0842 (wrong HAB4 format)"

# List generated certificates
echo ""
echo "  Generated certificates:"
ls -la "${CST_DIR}/crts/"*.pem 2>/dev/null || echo "  (no PEM files found)"

# Check private keys (list first 5)
echo ""
echo "  Generated private keys:"
ls -la "${CST_DIR}/keys/"*.pem 2>/dev/null | head -5

echo ""
echo "============================================"
echo "Key generation completed successfully!"
echo "============================================"
echo ""
echo "Generated files:"
echo "  Certificates:  ${CST_DIR}/crts/"
echo "  Private Keys:  ${CST_DIR}/keys/"
echo ""
echo "NEXT STEPS:"
echo "  1. BACK UP the keys/ directory immediately!"
echo "     cp -a ${CST_DIR}/keys /secure/backup/location/"
echo ""
echo "  2. Verify certificates match bbclass configuration:"
echo "     grep MYIR_AHAB_CST.*CURVE local.conf"
echo "     (Should be: secp384r1, sha384, SRK_CA=0)"
echo ""
echo "  3. Build with secure boot:"
echo "     MYIR_AHAB_ENABLE=\"1\" bitbake imx-boot"
echo ""
echo "  4. Burn SRK fuses (one-time, irreversible!):"
echo "     See gen_fuse_cmds.sh for fuse burning commands"
echo ""
echo "  5. Close the device:"
echo "     ahab_close (via U-Boot or SPSDK nxpele)"
echo ""
echo "WARNING: Private keys in ${CST_DIR}/keys/ MUST be kept secure."
echo "If lost, signed images cannot be updated without changing SRK fuses."
echo "SRK fuses are ONE-TIME programmable - cannot be changed after burning."
echo "============================================"
