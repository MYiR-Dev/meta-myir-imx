# linux-hab-sign.inc
# HABv4 Kernel Signing using IVT + CSF (NXP i.MX 6 Linux HAB Reference Method)
#
# This implements the NXP-documented method for kernel HAB authentication:
#   ROM (HABv4) -> U-Boot (HAB-signed) -> kernel (HAB-signed via IVT+CSF)
#
# The flow (matches manual genIVT + signed_zimage approach):
#   1. Auto-calculate pad_size = ALIGN(kernel_size, 0x1000)
#      (zImage padded to 4K boundary, no extra headroom)
#   2. Pad kernel image to pad_size (objcopy --pad-to)
#   3. Generate IVT (Image Vector Table) at pad_size offset
#   4. Append IVT to padded kernel
#   5. Generate CSF with CST (same certificate chain as U-Boot)
#   6. Append CSF to kernel+IVT
#   7. Pad final signed image to pad_size + 0x2000 (fixed 8KB tail)
#      This ensures U-Boot can calculate ivt_offset = filesize - 0x2000
#      at boot time without needing any external file (no hab_pad.bin needed).
#
# Boot-time U-Boot usage:
#   setexpr pad_off ${filesize} - 0x2000
#   hab_auth_img ${loadaddr} ${filesize} ${pad_off}
#
# This is MUTUALLY EXCLUSIVE with FIT Image signing (MYIR_FIT_ENABLE).
# Choose one trust chain:
#   HAB+IVT:   ROM HAB -> U-Boot (HAB) -> kernel (HAB IVT+CSF)
#   HAB+FIT:   ROM HAB -> U-Boot (HAB) -> fitImage (U-Boot FIT RSA)
#
# Guard: all additions are scoped to mx6ull-generic-bsp + MYIR_KERNEL_HAB_SIGN=1.
# Zero impact on i.MX95 (mx9-generic-bsp) builds.

inherit myir-hab

# ==========================================================================
# Pre-compute HAB values using inline Python (${@...}) which bitbake
# expands at parse time and embeds directly into shell function bodies.
#
# Anonymous Python functions (python do_xxx() { ... }) do NOT work here:
# variables they set via d.setVar() are not exported to the shell
# environment, so shell functions see them as empty.
#
# ${@...} inline expressions ARE expanded at parse time -> literal values
# appear in the generated run.do_deploy script.
#
# PAD_SIZE is auto-calculated at deploy time from the actual kernel
# binary size. The final signed image always has a fixed 8KB tail
# (0x2000) so U-Boot can derive the IVT offset without external data.
# ==========================================================================
MYIR_HAB_KERNEL_LOADADDR_DEC:mx6ull-generic-bsp = "${@int(d.getVar('MYIR_HAB_KERNEL_LOADADDR'), 16)}"
MYIR_HAB_CA_FLAG:mx6ull-generic-bsp = "${@'1' if '_ca_' in d.getVar('MYIR_HAB_CST_SRK_CERT') else '0'}"
MYIR_HAB_SRK_INDEX:mx6ull-generic-bsp = "${@str(int(d.getVar('MYIR_HAB_CST_SRK_CERT').split('/')[-1].split('_')[0].replace('SRK', '')) - 1)}"
MYIR_HAB_AUTH_KIDX:mx6ull-generic-bsp = "${@'2' if '_ca_' in d.getVar('MYIR_HAB_CST_SRK_CERT') else '0'}"

# ==========================================================================
# Add genIVT.sh to SRC_URI (only for mx6ull + kernel HAB signing enabled)
# ==========================================================================
SRC_URI:append:mx6ull-generic-bsp = " \
    ${@bb.utils.contains('MYIR_KERNEL_HAB_SIGN', '1', \
        'file://genIVT.sh', '', d)} \
"

# ==========================================================================
# Helper: pad value up to 4K (0x1000) boundary
# Uses expr because bitbake dependency analyzer cannot parse $((...))
# ==========================================================================

# ==========================================================================
# myir_hab_sign_kernel() - Sign kernel image using HABv4 IVT+CSF method
#
# Parameters:
#   $1 - path to kernel binary (e.g. ${B}/arch/arm/boot/zImage)
#
# NOTE: All arithmetic uses expr/POSIX utilities instead of $((...))
# because bitbake's shell dependency analyzer raises NotImplementedError
# on $(( ... )) constructs.
#
# PAD_SIZE is auto-calculated from the actual kernel binary size:
#   pad_size = ALIGN(orig_size, 0x1000)
#
# Final signed image = pad_size + 0x2000 (fixed 8KB tail):
#   ┌──────────┬──────┬───────┬──────────────────┐
#   │  zImage  │ IVT  │  CSF  │  padding (to 8K)  │
#   │ (padded) │(32B) │ (~4K) │                  │
#   └──────────┴──────┴───────┴──────────────────┘
#                ↑ pad_size                  ↑ pad_size + 0x2000
#
# U-Boot calculates: ivt_offset = filesize - 0x2000
# No external file (hab_pad.bin) needed.
# ==========================================================================
myir_hab_sign_kernel() {
    local kernel_binary="$1"

    if [ ! -f "${kernel_binary}" ]; then
        bbfatal "Kernel binary not found: ${kernel_binary}"
    fi

    local genivt="${UNPACKDIR}/genIVT.sh"
    if [ ! -x "${genivt}" ]; then
        bbfatal "genIVT.sh not found at ${genivt}"
    fi

    if [ ! -x "${MYIR_HAB_CST_BIN}" ]; then
        bbfatal "CST binary not found at ${MYIR_HAB_CST_BIN}. Set MYIR_HAB_CST_DIR."
    fi

    # ------------------------------------------------------------------
    # Step 1: Calculate sizes and DDR addresses
    # ------------------------------------------------------------------
    local orig_size=$(stat -c %s "${kernel_binary}")

    # pad_size = ALIGN(orig_size, 0x1000) — just the zImage, no extra headroom.
    # IVT (32B) + CSF (~4KB) + safety margin = fixed 8KB (0x2000) tail.
    local pad_size=$(expr \( $orig_size + 4095 \) / 4096 \* 4096 )

    # Safety check
    if [ $pad_size -lt $orig_size ]; then
        bbfatal "HAB kernel: auto-calculated pad_size (${pad_size} = 0x$(printf '%x' ${pad_size})) is smaller than kernel binary (${orig_size} bytes). This is a bug."
    fi

    local tail_size=8192   # 0x2000 = IVT (32B) + CSF (~4KB) + safety margin

    # DDR addresses: pre-computed by Python
    local load_addr_dec=${MYIR_HAB_KERNEL_LOADADDR_DEC}
    local ivt_addr_dec=$(expr $load_addr_dec + $pad_size)
    local csf_addr_dec=$(expr $ivt_addr_dec + 32)

    # Authentication range: kernel padded + IVT (CSF is self-authenticated)
    local auth_size=$(expr $pad_size + 32)

    bbnote "HAB kernel: orig_size=0x$(printf '%x' ${orig_size}) pad_size=0x$(printf '%x' ${pad_size}) (ALIGN(orig,4K))"
    bbnote "HAB kernel: load=0x$(printf '%x' ${load_addr_dec}) ivt=0x$(printf '%x' ${ivt_addr_dec}) csf=0x$(printf '%x' ${csf_addr_dec})"
    bbnote "HAB kernel: auth_range=0x0-0x$(printf '%x' ${auth_size}) (kernel+IVT, CSF self-authenticated)"

    # ------------------------------------------------------------------
    # Step 2: Pad kernel image to calculated pad_size (objcopy)
    # ------------------------------------------------------------------
    local kernel_padded="${WORKDIR}/kernel_padded.bin"
    objcopy -I binary -O binary --pad-to ${pad_size} --gap-fill=0x5A \
        "${kernel_binary}" "${kernel_padded}"
    bbnote "HAB kernel: padded kernel to 0x$(printf '%x' ${pad_size}) bytes (auto-calculated)"

    # ------------------------------------------------------------------
    # Step 3: Generate IVT at the pad_size offset
    # ------------------------------------------------------------------
    local ivt_bin="${WORKDIR}/kernel_ivt.bin"
    "${genivt}" \
        "0x$(printf '%x' ${load_addr_dec})" \
        "0x$(printf '%x' ${ivt_addr_dec})" \
        "0x$(printf '%x' ${csf_addr_dec})" \
        "${ivt_bin}"

    # ------------------------------------------------------------------
    # Step 4: Concatenate padded kernel + IVT
    # ------------------------------------------------------------------
    local kernel_pad_ivt="${WORKDIR}/kernel_pad_ivt.bin"
    cat "${kernel_padded}" "${ivt_bin}" > "${kernel_pad_ivt}"

    # ------------------------------------------------------------------
    # Step 5: CA flag, SRK index, auth key index (pre-computed by Python)
    # ------------------------------------------------------------------
    local ca=${MYIR_HAB_CA_FLAG}
    local kidx=${MYIR_HAB_SRK_INDEX}
    local auth_kidx=${MYIR_HAB_AUTH_KIDX}

    bbnote "HAB kernel: CA=${ca} SRK_index=${kidx} auth_kidx=${auth_kidx}"

    # ------------------------------------------------------------------
    # Step 6: Generate CSF file
    # ------------------------------------------------------------------
    local csf_file="${WORKDIR}/kernel.csf"
    local csf_bin="${WORKDIR}/kernel_csf.bin"

    # Build Block parameter string
    # Format: <start_addr_hex> <offset_hex> <length_hex> "<filename>"
    local blocks_str="0x$(printf '%x' ${load_addr_dec}) 0x0 0x$(printf '%x' ${auth_size}) \"kernel_pad_ivt.bin\""

    # Write CSF header (common to CA and non-CA)
    cat > "${csf_file}" <<CSFHEADER
[Header]
    Version = 4.2
    Hash Algorithm = sha256
    Engine = SW
    Engine Configuration = 0
    Certificate Format = X509
    Signature Format = CMS

[Install SRK]
    File = "${MYIR_HAB_CST_SRK}"
    Source index = ${kidx}
CSFHEADER

    if [ "${ca}" = "1" ]; then
        # CA mode: Install CSFK + Install Key + Authenticate with IMG key
        cat >> "${csf_file}" <<CSFCA
[Install CSFK]
    File = "${MYIR_HAB_CST_CSF_CERT}"

[Authenticate CSF]

[Install Key]
    Verification index = 0
    Target index = 2
    File = "${MYIR_HAB_CST_IMG_CERT}"

[Authenticate Data]
    Verification index = ${auth_kidx}
    Blocks = ${blocks_str}
CSFCA
    else
        # Non-CA mode: Install NOCAK + Authenticate directly with SRK
        cat >> "${csf_file}" <<CSFNOCA
[Install NOCAK]
    File = "${MYIR_HAB_CST_SRK_CERT}"

[Authenticate CSF]

[Authenticate Data]
    Verification index = ${auth_kidx}
    Blocks = ${blocks_str}
CSFNOCA
    fi

    bbdebug 1 "HAB kernel: CSF file generated at ${csf_file}"

    # ------------------------------------------------------------------
    # Step 7: Run CST to generate CSF binary
    # ------------------------------------------------------------------
    bbnote "HAB kernel: running CST to sign kernel image..."
    (
        cd "${WORKDIR}"  # CST reads the file referenced in Blocks (kernel_pad_ivt.bin)
        ${MYIR_HAB_CST_BIN} --o "${csf_bin}" --i "${csf_file}"
    )
    if [ ! -f "${csf_bin}" ]; then
        bbfatal "CST failed to generate CSF binary"
    fi
    bbnote "HAB kernel: CSF binary generated ($(stat -c %s ${csf_bin}) bytes)"

    # ------------------------------------------------------------------
    # Step 8: Concatenate kernel_pad_ivt + CSF binary -> signed kernel
    # ------------------------------------------------------------------
    local signed_kernel="${WORKDIR}/signed_kernel.bin"
    cat "${kernel_pad_ivt}" "${csf_bin}" > "${signed_kernel}"

    # ------------------------------------------------------------------
    # Step 9: Pad to fixed tail: pad_size + 0x2000
    #
    # This ensures a CONSTANT relationship:
    #   ivt_offset = filesize - 0x2000
    #
    # U-Boot can calculate IVT position from the loaded file size
    # without any external file. Matches the manual genIVT/signed_zimage
    # approach where final image = ALIGN(zImage,4K) + 0x2000.
    # ------------------------------------------------------------------
    local final_pad=$(expr $pad_size + $tail_size)

    local signed_kernel_pad="${WORKDIR}/signed_kernel_padded.bin"
    objcopy -I binary -O binary --pad-to ${final_pad} --gap-fill=0x5A \
        "${signed_kernel}" "${signed_kernel_pad}"

    bbnote "HAB kernel: final signed size = 0x$(printf '%x' ${final_pad}) (fixed tail: pad_size + 0x2000)"

    # ------------------------------------------------------------------
    # Step 10: Replace original kernel with signed version
    # ------------------------------------------------------------------
    cp "${kernel_binary}" "${kernel_binary}-unsigned"
    cp "${signed_kernel_pad}" "${kernel_binary}"
    bbnote "HAB kernel: signed kernel written to ${kernel_binary} (unsigned backup: ${kernel_binary}-unsigned)"
}

# ==========================================================================
# Hook: sign kernel BEFORE do_deploy, so the signed version gets deployed
# ==========================================================================
do_deploy:prepend:mx6ull-generic-bsp() {
    if [ "${MYIR_KERNEL_HAB_SIGN}" != "1" ]; then
        return 0
    fi

    # Determine kernel binary location in build tree
    # KERNEL_OUTPUT_DIR = arch/${ARCH}/boot (e.g. arch/arm/boot)
    local kernel_binary="${B}/${KERNEL_OUTPUT_DIR}/${KERNEL_IMAGETYPE}"

    if [ ! -f "${kernel_binary}" ]; then
        bbfatal "HAB kernel: cannot find kernel binary at ${kernel_binary}"
    fi

    bbnote "HAB kernel: signing ${KERNEL_IMAGETYPE} with IVT+CSF method (fixed 8KB tail)"
    bbnote "HAB kernel: load address = ${MYIR_HAB_KERNEL_LOADADDR}"

    myir_hab_sign_kernel "${kernel_binary}"
}
