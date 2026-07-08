#!/bin/bash
# ============================================================================
# genIVT.sh - Generate HABv4 IVT (Image Vector Table) for kernel signing
#
# Based on NXP i.MX 6 Linux HAB User's Guide (Rev L3.10.17_1.0.0-ga).
# Ported from NXP's Perl genIVT to bash for Yocto OE integration.
#
# IVT layout (32 bytes, 8 x 32-bit little-endian):
#   Offset 0x00: Tag/Header     (0x412000D1 = HABv4.1)
#   Offset 0x04: Entry/Jump     (kernel load address in DDR)
#   Offset 0x08: Reserved1      (0x00000000)
#   Offset 0x0C: DCD pointer    (0x00000000, kernel has no DCD)
#   Offset 0x10: Boot Data ptr  (0x00000000, kernel has no Boot Data)
#   Offset 0x14: Self Pointer   (IVT location in DDR = load_addr + pad_size)
#   Offset 0x18: CSF Pointer    (CSF location in DDR = self_addr + 0x20)
#   Offset 0x1C: Reserved2      (0x00000000)
#
# Usage: genIVT.sh <load_addr> <self_addr> <csf_addr> <output_file>
#   All addresses in hex (with or without 0x prefix)
# ============================================================================

set -e

usage() {
    echo "Usage: $0 <load_addr> <self_addr> <csf_addr> <output_file>"
    echo "  All addresses in hex (e.g. 0x80800000 or 80800000)"
    exit 1
}

[ $# -eq 4 ] || usage

# Parse hex addresses (strip 0x prefix if present)
LOAD_ADDR=$(( 0x${1#0x} ))
SELF_ADDR=$(( 0x${2#0x} ))
CSF_ADDR=$(( 0x${3#0x} ))
OUTPUT="$4"

# HABv4.1 IVT tag (Version 4.1, DCD=1 for image type)
# Tag format: [31:24]=HAB major ver, [23:0]=0x2000D1 (0x41 = v4.1)
IVT_TAG=$(( 0x412000D1 ))

echo "genIVT: load=0x$(printf '%08x' ${LOAD_ADDR}) self=0x$(printf '%08x' ${SELF_ADDR}) csf=0x$(printf '%08x' ${CSF_ADDR})"

# Helper: emit little-endian hex bytes for a 32-bit value.
# i.MX ROM reads IVT in little-endian; plain printf|xxd gives big-endian.
le32() {
    local val_hex
    val_hex=$(printf '%08x' "$1")
    printf '%s%s%s%s' \
        "$(echo "$val_hex" | cut -c7-8)" \
        "$(echo "$val_hex" | cut -c5-6)" \
        "$(echo "$val_hex" | cut -c3-4)" \
        "$(echo "$val_hex" | cut -c1-2)"
}

# Write 8 little-endian 32-bit words to output
{
    le32 ${IVT_TAG}      # 0x00: Tag
    le32 ${LOAD_ADDR}    # 0x04: Entry / Jump Location
    printf '%08x' 0      # 0x08: Reserved1
    printf '%08x' 0      # 0x0C: DCD pointer (n/a for kernel)
    printf '%08x' 0      # 0x10: Boot Data pointer (n/a for kernel)
    le32 ${SELF_ADDR}    # 0x14: Self Pointer
    le32 ${CSF_ADDR}     # 0x18: CSF Pointer
    printf '%08x' 0      # 0x1C: Reserved2
} | xxd -r -p > "${OUTPUT}"

echo "genIVT: wrote $(stat -c %s "${OUTPUT}") bytes to ${OUTPUT}"
