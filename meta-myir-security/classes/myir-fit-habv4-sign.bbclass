# myir-fit-habv4-sign.bbclass
# i.MX6/7 HABv4 FIT Image Signing for Kernel fitImage
#
# Signs the kernel fitImage (.itb) with HABv4 so U-Boot's
# authenticate_image() in do_bootm() can verify it at boot time.
#
# The signing flow (performed by mx6ull_sign_fit.sh):
#   1. genIVT_fit.sh    → generates IVT at ALIGN(fit_size, 0x1000)
#   2. Pad FIT + append IVT
#   3. Generate HABv4 CSF from template (substitute placeholders)
#   4. Run NXP CST → CSF binary
#   5. Append CSF → Final signed image
#
# Prerequisites:
#   - NXP CST tool (cst) installed and accessible
#   - HABv4 PKI keys generated (hab4_pki_tree.sh from NXP CST)
#   - SRK fuses programmed (for closed device; dev mode works without)
#   - U-Boot CONFIG_IMX_HAB=y with FIT authentication patch applied
#   - MX6ULL_GENIVT_FIT / MX6ULL_SIGN_FIT scripts accessible
#
# Usage in local.conf:
#   INHERIT += "myir-fit-habv4-sign"
#
# All signing variables are auto-derived from the existing HAB infrastructure
# (MYIR_HAB_CST_* set in layer.conf + machine config).  Set any MYIR_HABV4_*
# explicitly only if you need to override a specific path.
#
# Variables with auto-defaults (from existing MYIR_HAB_CST_* in layer.conf):
#   MYIR_HABV4_CST_BIN         ← MYIR_HAB_CST_BIN
#   MYIR_HABV4_SRK_TABLE       ← ${MYIR_HAB_CST_DIR}/crts/SRK_1_2_3_4_table.bin
#   MYIR_HABV4_CSF_KEY         ← auto-derived cert name (CSF<idx>_...usr_crt.pem)
#   MYIR_HABV4_IMG_KEY         ← auto-derived cert name (IMG<idx>_...usr_crt.pem)
#   MYIR_HABV4_SRK_SOURCE_IDX  ← MYIR_HAB_CST_SRK_INDEX - 1  (0-based for CST)
#   MYIR_HABV4_IMG_IDX         ← 2 if CA key else 0
#   MYIR_HABV4_IMAGE_LOAD_ADDR ← MYIR_HAB_KERNEL_LOADADDR (default 0x80800000)
#   MYIR_HABV4_FIT_SIGN_ENABLE ← auto from SOC_FAMILY (mx6/mx6ul/mx6ull/mx7)

# ==========================================================================
# Helper: build HABv4 certificate file name from key parameters
# ==========================================================================
def _myir_habv4_cert_name(d, cert_type):
    """Derive HABv4 cert file name.

    Pattern for SRK:  SRK<idx>_1_<dig>_<ksize>_<kexp>_v3_<ca|usr>_crt.pem
    Pattern for CSF/IMG: CSF<idx>_1_<dig>_<ksize>_<kexp>_v3_usr_crt.pem
    """
    srk_idx  = d.getVar('MYIR_HAB_CST_SRK_INDEX') or '1'
    crypto   = d.getVar('MYIR_HAB_CST_CRYPTO') or 'rsa'
    dalgo    = d.getVar('MYIR_HAB_CST_DIG_ALGO') or 'sha256'
    ksize    = d.getVar('MYIR_HAB_CST_KEY_SIZE') or '2048'
    kexp     = d.getVar('MYIR_HAB_CST_KEY_EXP') or '65537'
    ca_flag  = d.getVar('MYIR_HAB_CST_SRK_CA') or '1'
    basedir  = d.getVar('MYIR_HAB_CST_DIR') or '${TOPDIR}/keys/cst'

    if cert_type == 'SRK':
        suffix = 'ca' if ca_flag == '1' else 'usr'
    else:
        suffix = 'usr'

    name = '{}{}_1_{}_{}_{}_v3_{}_crt.pem'.format(
        cert_type, srk_idx, dalgo, ksize, kexp, suffix)
    return '{}/crts/{}'.format(basedir, name)

# ==========================================================================
# Auto-detect enable based on SOC_FAMILY
# ==========================================================================
MYIR_HABV4_FIT_SIGN_ENABLE ??= "${@bb.utils.contains_any('SOC_FAMILY', \
    'mx6 mx6sl mx6sll mx6sx mx6ul mx6ull mx7 mx7d mx7ulp', '1', '0', d)}"

# ==========================================================================
# Signing parameters — all auto-derived from existing MYIR_HAB_CST_* vars
# Override with = in local.conf/machine config if you need non-standard paths.
# ==========================================================================
MYIR_HABV4_CST_BIN        ??= "${MYIR_HAB_CST_BIN}"
MYIR_HABV4_SRK_TABLE      ??= "${MYIR_HAB_CST_DIR}/crts/SRK_1_2_3_4_table.bin"
MYIR_HABV4_CSF_KEY        ??= "${@_myir_habv4_cert_name(d, 'CSF')}"
MYIR_HABV4_IMG_KEY        ??= "${@_myir_habv4_cert_name(d, 'IMG')}"
MYIR_HABV4_IMAGE_LOAD_ADDR ??= "${MYIR_HAB_KERNEL_LOADADDR}"

# SRK index in CST Sources block is 0-based (HABv4 CST convention).
# MYIR_HAB_CST_SRK_INDEX is 1-based, so subtract 1.
MYIR_HABV4_SRK_SOURCE_IDX ??= "${@str(int(d.getVar('MYIR_HAB_CST_SRK_INDEX') or '1') - 1)}"

# IMG key install slot: 2 for CA key, 0 for non-CA key.
MYIR_HABV4_IMG_IDX        ??= "${@'2' if (d.getVar('MYIR_HAB_CST_SRK_CA') or '1') == '1' else '0'}"

MYIR_HABV4_CST_ARGS       ??= ""

# ==========================================================================
# Script paths (defaults based on layer layout)
# ==========================================================================
MX6ULL_HABV4_DIR             ??= "${BSPDIR}/sources/meta-myir/meta-myir-security/recipes-bsp/imx-mkimage/files/mx6ull_habv4"
MX6ULL_GENIVT_FIT            ??= "${MX6ULL_HABV4_DIR}/genIVT_fit.sh"
MX6ULL_SIGN_FIT              ??= "${MX6ULL_HABV4_DIR}/mx6ull_sign_fit.sh"
MX6ULL_CSF_TEMPLATE          ??= "${MX6ULL_HABV4_DIR}/mx6ull_fit_habv4.csf.template"

# ==========================================================================
# Kernel image type to sign
# ==========================================================================
MYIR_HABV4_FIT_IMAGE_TYPE ??= "fitImage"

# ==========================================================================
# Signing task — runs after kernel deploy
# ==========================================================================
do_habv4_sign_fit() {
    if [ "${MYIR_HABV4_FIT_SIGN_ENABLE}" != "1" ]; then
        bbnote "FIT HABv4 signing disabled (MYIR_HABV4_FIT_SIGN_ENABLE != 1), skipping"
        return 0
    fi

    # ----------------------------------------------------------------
    # Verify prerequisites
    # ----------------------------------------------------------------
    if [ ! -x "${MX6ULL_SIGN_FIT}" ]; then
        bbfatal "mx6ull_sign_fit.sh not found or not executable: ${MX6ULL_SIGN_FIT}"
    fi

    if [ ! -x "${MX6ULL_GENIVT_FIT}" ]; then
        bbfatal "genIVT_fit.sh not found or not executable: ${MX6ULL_GENIVT_FIT}"
    fi

    if [ ! -f "${MX6ULL_CSF_TEMPLATE}" ]; then
        bbfatal "CSF template not found: ${MX6ULL_CSF_TEMPLATE}"
    fi

    if [ ! -x "${MYIR_HABV4_CST_BIN}" ]; then
        bbfatal "CST binary not found: ${MYIR_HABV4_CST_BIN}"
    fi

    if [ ! -f "${MYIR_HABV4_SRK_TABLE}" ]; then
        bbfatal "SRK table not found: ${MYIR_HABV4_SRK_TABLE}"
    fi

    # ----------------------------------------------------------------
    # Find the unsigned fitImage in deploy directory
    # ----------------------------------------------------------------
    # fitImage is deployed as: fitImage-<machine>.bin  or  fitImage
    # The kernel-fitimage class deploys it with KERNEL_FIT_LINK_NAME
    fit_image_unsigned=""
    for candidate in \
        "${DEPLOY_DIR_IMAGE}/fitImage-${MACHINE}.bin" \
        "${DEPLOY_DIR_IMAGE}/fitImage-${MACHINE}${KERNEL_FIT_BIN_EXT}" \
        "${DEPLOY_DIR_IMAGE}/fitImage" \
        "${DEPLOY_DIR_IMAGE}/${MYIR_HABV4_FIT_IMAGE_TYPE}" \
        "${DEPLOY_DIR_IMAGE}/${MYIR_HABV4_FIT_IMAGE_TYPE}-${MACHINE}.bin" \
    ; do
        if [ -f "$candidate" ]; then
            fit_image_unsigned="$candidate"
            break
        fi
    done

    if [ -z "$fit_image_unsigned" ]; then
        bbwarn "Unsigned fitImage not found in ${DEPLOY_DIR_IMAGE}"
        bbwarn "Searched: fitImage, fitImage-${MACHINE}.bin"
        bbwarn "FIT HABv4 signing skipped — image not found"
        return 0
    fi

    bbnote "============================================"
    bbnote "HABv4 FIT Signing: $(basename $fit_image_unsigned)"
    bbnote "============================================"
    bbnote "  Unsigned:      $fit_image_unsigned"
    bbnote "  Load addr:     ${MYIR_HABV4_IMAGE_LOAD_ADDR}"
    bbnote "  CST:           ${MYIR_HABV4_CST_BIN}"
    bbnote "  SRK index:     ${MYIR_HABV4_SRK_SOURCE_IDX}"

    # ----------------------------------------------------------------
    # Output paths
    # ----------------------------------------------------------------
    fit_image_signed="${WORKDIR}/fitImage-${MACHINE}-signed.bin"
    csf_output="${WORKDIR}/csf_fit_habv4.txt"

    # ----------------------------------------------------------------
    # Content-based caching: skip signing if unsigned image unchanged
    # ----------------------------------------------------------------
    fit_md5=$(md5sum "$fit_image_unsigned" | awk '{print $1}')
    cache_dir="${WORKDIR}/habv4_cache"
    cache_md5_file="${cache_dir}/unsigned_md5"
    cache_signed_bin="${cache_dir}/fitImage-${MACHINE}-signed.bin"

    if [ -f "$cache_md5_file" ] && [ -f "$cache_signed_bin" ]; then
        cached_md5=$(cat "$cache_md5_file")
        if [ "$fit_md5" = "$cached_md5" ]; then
            bbnote "Unsigned fitImage unchanged (md5=$fit_md5) -- using cached signed image"
            cp "$cache_signed_bin" "$fit_image_signed"

            # Deploy directly from cache
            install -d ${DEPLOY_DIR_IMAGE}
            install -m 0644 "$fit_image_signed" ${DEPLOY_DIR_IMAGE}/
            ln -sf "fitImage-${MACHINE}-signed.bin" "${DEPLOY_DIR_IMAGE}/fitImage-signed"
            bbnote "Deployed signed fitImage from cache: fitImage-${MACHINE}-signed.bin"
            return 0
        fi
    fi

    # ----------------------------------------------------------------
    # Run signing script
    # ----------------------------------------------------------------
    bbnote "  Signing with mx6ull_sign_fit.sh..."

    export MYIR_HABV4_CST_BIN="${MYIR_HABV4_CST_BIN}"
    export MYIR_HABV4_CSF_TEMPLATE="${MX6ULL_CSF_TEMPLATE}"
    export MYIR_HABV4_SRK_TABLE="${MYIR_HABV4_SRK_TABLE}"
    export MYIR_HABV4_SRK_SOURCE_IDX="${MYIR_HABV4_SRK_SOURCE_IDX}"
    export MYIR_HABV4_CSF_KEY="${MYIR_HABV4_CSF_KEY}"
    export MYIR_HABV4_IMG_KEY="${MYIR_HABV4_IMG_KEY}"
    export MYIR_HABV4_IMG_IDX="${MYIR_HABV4_IMG_IDX}"
    export MYIR_HABV4_IMAGE_LOAD_ADDR="${MYIR_HABV4_IMAGE_LOAD_ADDR}"
    export GENIVT_FIT_SCRIPT="${MX6ULL_GENIVT_FIT}"
    export MYIR_HABV4_CST_ARGS="${MYIR_HABV4_CST_ARGS}"

    ${MX6ULL_SIGN_FIT} "$fit_image_unsigned" "$fit_image_signed"
    sign_ret=$?

    if [ $sign_ret -ne 0 ]; then
        bbfatal "FIT HABv4 signing failed (exit code: $sign_ret)"
    fi

    if [ ! -f "$fit_image_signed" ]; then
        bbfatal "Signed fitImage not produced: $fit_image_signed"
    fi

    bbnote "  Signed output: $fit_image_signed ($(stat -c%s "$fit_image_signed") bytes)"
    bbnote "============================================"

    # Cache the signed result for reuse on next build
    mkdir -p "$cache_dir"
    cp "$fit_image_signed" "$cache_signed_bin"
    echo "$fit_md5" > "$cache_md5_file"
    bbnote "Cached signed image (md5=$fit_md5)"

    # ----------------------------------------------------------------
    # Deploy signed fitImage alongside unsigned
    # ----------------------------------------------------------------
    # Doing this HERE (not in do_deploy:append) because the signing
    # runs AFTER do_deploy.  If FIT content changed, do_deploy has
    # already run by the time we reach this point; we re-deploy the
    # newly signed image on every signing run.
    install -d ${DEPLOY_DIR_IMAGE}
    install -m 0644 "$fit_image_signed" ${DEPLOY_DIR_IMAGE}/

    # Symlink with stable name: fitImage-signed
    ln -sf "fitImage-${MACHINE}-signed.bin" \
        "${DEPLOY_DIR_IMAGE}/fitImage-signed"

    bbnote "Deployed signed fitImage: fitImage-${MACHINE}-signed.bin"
}

# Run after the kernel recipe deploys the unsigned fitImage.
# [nostamp]=1 ensures the task always executes; md5sum-based caching
# inside the task skips CST invocation when the unsigned fitImage
# has not changed, making repeated builds fast.
addtask do_habv4_sign_fit after do_deploy before do_build
do_habv4_sign_fit[depends] += "virtual/kernel:do_deploy"
do_habv4_sign_fit[nostamp] = "1"
