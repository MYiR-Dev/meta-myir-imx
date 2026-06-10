# myir-kernel-container-sign.bbclass
# i.MX95 AHAB Kernel Container (OS Container) Signing
#
# Based on NXP csf_linux_img.csf pattern — CST runs from the staging
# directory (iMX95/) with all paths relative:
#   crts/SRK_1_2_3_4_tables.bin   (symlink -> actual cert dir)
#   crts/SRK1_..._crt.pem
#   flash_os.bin                  (kernel container binary)
#
# Kernel container signing flow:
#   1. Copy kernel Image + DTB to imx-mkimage iMX95/ directory
#   2. Rename DTB to imx95-19x19-evk.dtb (hardcoded in mkimage)
#   3. make flash_kernel -> produces flash_os.bin
#   4. Create crts/ keys/ symlinks in iMX95/
#   5. Parse container/signature offsets from mkimage log
#      (defaults: container=0x0, signature=0x110)
#   6. Generate CSF with relative paths
#   7. Run CST from iMX95/ -> os_cntr_signed.bin
#   8. Copy signed binary to WORKDIR for deploy
#
# Reference:
#   - NXP CST example: csf_linux_img.csf
#   - NXP: imx-boot-hab.inc (AHAB container signing reference)
#   - NXP: cst-4.0.1 csf_linux_img.csf example

# ==========================================================================
# Inherit AHAB signing base class for shared variables
# ==========================================================================
inherit myir-ahab

# ==========================================================================
# Kernel container signing control
# ==========================================================================

# Enable/disable kernel container signing.
# Default: auto-enabled when MYIR_AHAB_ENABLE=1 (kernel must be signed in
# secure boot chain).
MYIR_KERNEL_CONTAINER_ENABLE ?= "${MYIR_AHAB_ENABLE}"

# ==========================================================================
# Kernel image and device tree paths
# ==========================================================================

# Kernel image name (as deployed by virtual/kernel:do_deploy)
MYIR_KERNEL_CONTAINER_IMAGE ?= "Image"

# Device trees to build kernel containers for.
# Default: use KERNEL_DEVICETREE from machine config (space-separated list).
# Each DTB gets its own kernel container.
# Override in local.conf to select specific DTBs for signing.
MYIR_KERNEL_CONTAINER_DTBS ?= "${KERNEL_DEVICETREE}"

# The DTB name that mkimage expects inside the kernel container.
# For i.MX95, soc.mak hardcodes "imx95-19x19-evk.dtb" in the
# mkimage_imx8 invocation. The user's DTB must be renamed to match.
MYIR_KERNEL_CONTAINER_DTB_RENAME:mx95-generic-bsp ?= "imx95-19x19-evk.dtb"
MYIR_KERNEL_CONTAINER_DTB_RENAME:mx93-generic-bsp ?= "imx93-11x11-evk.dtb"

# ==========================================================================
# Kernel container make target
# ==========================================================================

# The make target for kernel container in imx-mkimage
MYIR_KERNEL_CONTAINER_TARGET ?= "flash_kernel"

# Additional make arguments for flash_kernel
MYIR_KERNEL_CONTAINER_MAKE_ARGS ?= ""

# ==========================================================================
# Output naming (matching NXP csf_linux_img.csf convention)
# ==========================================================================

# Kernel container produced by make flash_kernel (matches NXP kernel container naming).
# NXP soc.mak may use "flash.bin"; this variable allows override.
MYIR_KERNEL_CONTAINER_FLASH_BIN ?= "flash_os.bin"

# Signed kernel container output name prefix.
# Result: os_cntr_signed.bin (for default DTB)
#          os_cntr_signed_<variant>.bin (for additional DTBs)
MYIR_KERNEL_CONTAINER_SIGNED_PREFIX ?= "os_cntr_signed"

# ==========================================================================
# Kernel container signing task
#
# Runs after do_ahab_sign (boot container signed) and before do_install.
# The kernel container depends on kernel artifacts being deployed.
# ==========================================================================

do_sign_kernel_container() {
    # Only run if kernel container signing is enabled
    if [ "${MYIR_KERNEL_CONTAINER_ENABLE}" != "1" ]; then
        bbnote "Kernel container signing disabled (MYIR_KERNEL_CONTAINER_ENABLE != 1), skipping"
        return 0
    fi

    # Only apply to mx95/mx9 family
    case "${SOC_FAMILY}" in
        mx95|mx943)
            bbnote "Kernel container signing enabled for ${SOC_FAMILY}"
            ;;
        *)
            bbnote "Kernel container signing skipped for ${SOC_FAMILY}"
            return 0
            ;;
    esac

    bbnote "============================================"
    bbnote "AHAB Kernel Container Signing - ${SOC_FAMILY}"
    bbnote "============================================"

    # ------------------------------------------------------------------
    # Verify prerequisites
    # ------------------------------------------------------------------
    if [ ! -x "${MYIR_AHAB_CST_BIN}" ]; then
        bbfatal "CST binary not found: ${MYIR_AHAB_CST_BIN}"
    fi

    if [ ! -f "${MYIR_AHAB_CST_SRK}" ]; then
        bbfatal "SRK table not found: ${MYIR_AHAB_CST_SRK}"
    fi

    if [ ! -f "${DEPLOY_DIR_IMAGE}/${MYIR_KERNEL_CONTAINER_IMAGE}" ]; then
        bbfatal "Kernel image not found: ${DEPLOY_DIR_IMAGE}/${MYIR_KERNEL_CONTAINER_IMAGE}"
    fi

    # ------------------------------------------------------------------
    # Set up staging directory in imx-mkimage source tree
    # ------------------------------------------------------------------
    staging="${S}/${IMX_BOOT_SOC_TARGET}"
    if [ ! -d "$staging" ]; then
        bbfatal "imx-mkimage staging dir not found: $staging"
    fi

    # ------------------------------------------------------------------
    # Create crts/ and keys/ symlinks in staging directory.
    #
    # Matching NXP csf_linux_img.csf pattern, CST runs from $staging
    # and references key material via relative paths:
    #   File   = "crts/SRK_1_2_3_4_tables.bin"
    #   Source = "crts/SRK1_sha384_secp384r1_v3_usr_crt.pem"
    #
    # The CSF also references the binary to sign by local name only:
    #   File = "flash_os.bin"
    #
    # We additionally create keys/ symlink (may be needed for SGK flow).
    # ------------------------------------------------------------------
    if [ ! -d "$staging/keys" ]; then
        ln -sfn "${MYIR_AHAB_CST_KEYS_DIR}" "$staging/keys"
    fi
    if [ ! -d "$staging/crts" ]; then
        ln -sfn "${MYIR_AHAB_CST_CERTS_DIR}" "$staging/crts"
    fi

    # Extract SRK table and cert basenames for relative CSF paths
    srk_table_bn=$(basename "${MYIR_AHAB_CST_SRK}")
    srk_cert_bn=$(basename "${MYIR_AHAB_CST_SRK_CERT}")

    # ------------------------------------------------------------------
    # Copy kernel Image to staging directory
    # ------------------------------------------------------------------
    bbnote "Copying kernel Image to $staging/"
    cp "${DEPLOY_DIR_IMAGE}/${MYIR_KERNEL_CONTAINER_IMAGE}" "$staging/Image"

    # ------------------------------------------------------------------
    # Process each device tree
    # ------------------------------------------------------------------
    dtb_count=0

    for dtb_path in ${MYIR_KERNEL_CONTAINER_DTBS}; do
        # Extract basename (e.g. myir/myd-jmx95-15x15.dtb -> myd-jmx95-15x15.dtb)
        dtb_basename=$(basename "$dtb_path")
        dtb_deploy="${DEPLOY_DIR_IMAGE}/$dtb_basename"

        if [ ! -f "$dtb_deploy" ]; then
            bbwarn "DTB not found: $dtb_deploy, skipping"
            continue
        fi

        dtb_count=$(expr $dtb_count + 1)
        dtb_base="${dtb_basename%.dtb}"

        # Derive output name suffix from DTB name
        suffix=""
        if [ "$dtb_base" != "${KERNEL_DEVICETREE_BASENAME}" ]; then
            suffix="${dtb_base#${KERNEL_DEVICETREE_BASENAME}}"
            suffix="${suffix#-}"
            if [ -n "$suffix" ]; then
                suffix="_${suffix}"
            fi
        fi

        signed_name="${MYIR_KERNEL_CONTAINER_SIGNED_PREFIX}${suffix}.bin"
        csf_name="csf_linux_img${suffix}.csf"

        bbnote "---"
        bbnote "DTB: $dtb_basename"
        bbnote "  -> Signed output: $signed_name"
        bbnote "  -> CSF file:      $csf_name"

        # ----------------------------------------------------------------
        # Step 1: Copy DTB to staging with renamed name
        # ----------------------------------------------------------------
        bbnote "  Copying DTB as ${MYIR_KERNEL_CONTAINER_DTB_RENAME}"
        cp "$dtb_deploy" "$staging/${MYIR_KERNEL_CONTAINER_DTB_RENAME}"

        # ----------------------------------------------------------------
        # Step 2: Build kernel container via make flash_kernel
        #
        # The flash_kernel target in soc.mak calls mkimage_imx8:
        #   -ap Image a55 0x90400000          (kernel load addr)
        #   --data imx95-19x19-evk.dtb a55 0x93000000  (DTB load addr)
        #   -out ${MYIR_KERNEL_CONTAINER_FLASH_BIN}
        #
        # Output: ${staging}/${MYIR_KERNEL_CONTAINER_FLASH_BIN}
        #         (flash_os.bin (NXP kernel container), or flash.bin in some NXP forks)
        # ----------------------------------------------------------------
        kernel_log="${WORKDIR}/mkimage-flash_kernel-${dtb_base}.log"
        bbnote "  Building kernel container (make ${MYIR_KERNEL_CONTAINER_TARGET})..."

        # Clean up stale kernel container binaries from previous loop iterations.
        # soc.mak outputs flash.bin; it gets renamed to flash_os.bin afterward.
        # Without cleanup, flash_os.bin from iteration N is reused in iteration N+1,
        # causing all os_cntr_signed_*.bin files to contain the same (first) DTB.
        rm -f "$staging/${MYIR_KERNEL_CONTAINER_FLASH_BIN}" "$staging/flash.bin"

        dtbs_arg="${dtb_basename}"

        cd "${S}"
        make SOC="${IMX_BOOT_SOC_TARGET}" \
             ${REV_OPTION} \
             ${MKIMAGE_EXTRA_ARGS} \
             ${MYIR_KERNEL_CONTAINER_MAKE_ARGS} \
             dtbs="$dtbs_arg" \
             ${MYIR_KERNEL_CONTAINER_TARGET} \
             > "$kernel_log" 2>&1
        make_ret=$?
        cd - > /dev/null

        if [ $make_ret -ne 0 ]; then
            bbwarn "make flash_kernel failed (exit code: $make_ret)"
            bbwarn "Check log: $kernel_log"
            continue
        fi

        # ----------------------------------------------------------------
        # Step 3: Locate the kernel container binary
        #
        # Try the configured name first (flash_os.bin), fall back to
        # flash.bin for compatibility with different imx-mkimage forks.
        # ----------------------------------------------------------------
        flash_bin="$staging/${MYIR_KERNEL_CONTAINER_FLASH_BIN}"
        if [ ! -f "$flash_bin" ]; then
            # Fallback: some NXP soc.mak use "flash.bin" as output name
            if [ -f "$staging/flash.bin" ]; then
                flash_bin="$staging/flash.bin"
                bbnote "  Using fallback output: flash.bin"
            else
                bbwarn "Kernel container not found: expected ${MYIR_KERNEL_CONTAINER_FLASH_BIN} or flash.bin"
                bbwarn "Check log: $kernel_log"
                continue
            fi
        fi

        # Rename to canonical name if using fallback
        if [ "$(basename "$flash_bin")" != "${MYIR_KERNEL_CONTAINER_FLASH_BIN}" ]; then
            mv "$flash_bin" "$staging/${MYIR_KERNEL_CONTAINER_FLASH_BIN}"
            flash_bin="$staging/${MYIR_KERNEL_CONTAINER_FLASH_BIN}"
        fi

        bbnote "  Kernel container: ${MYIR_KERNEL_CONTAINER_FLASH_BIN} ($(stat -c%s "$flash_bin") bytes)"

        # ----------------------------------------------------------------
        # Step 4: Parse CST offsets from mkimage log
        #
        # Kernel container output (no SPL/DDR FW prefix):
        #   CST: CONTAINER 0 offset: 0x0
        #   CST: CONTAINER 0: Signature Block: offset is at 0x110
        #
        # Unlike boot container (0x8000/0x8310), kernel container starts
        # at offset 0 with the AHAB container header.
        # ----------------------------------------------------------------
        cntr_offset=$(grep "CST: CONTAINER 0 offset:" "$kernel_log" | tail -1 | awk '{print $5}')
        sig_offset=$(grep "CST: CONTAINER 0: Signature Block" "$kernel_log" | tail -1 | awk '{print $9}')

        if [ -z "$cntr_offset" ] || [ -z "$sig_offset" ]; then
            bbwarn "Failed to parse CST offsets from mkimage log, using fallback defaults"
            cntr_offset="0x0"
            sig_offset="0x110"
        fi
        bbnote "  Container offsets: container=$cntr_offset signature=$sig_offset"

        # ----------------------------------------------------------------
        # Step 5: Generate AHAB CSF for kernel container
        #
        # Matching NXP csf_linux_img.csf — ALL PATHS RELATIVE:
        #   [Install SRK]
        #     File   = "crts/<SRK_table>.bin"
        #     Source = "crts/<SRK_cert>.pem"
        #   [Authenticate Data]
        #     File    = "flash_os.bin"
        #     Offsets = 0x0  0x110
        #
        # Reuses mx95_gen_csf.py (same template, just relative paths).
        # ------------------------------------------------------------------
        csf_file="$staging/$csf_name"

        python3 ${MYIR_AHAB_GEN_CSF_SCRIPT} \
            "${MYIR_AHAB_CSF_TEMPLATE}" \
            "$csf_file" \
            --srk-table "crts/$srk_table_bn" \
            --srk-cert "crts/$srk_cert_bn" \
            --srk-source-idx "${MYIR_AHAB_CST_SRK_SOURCE_IDX}" \
            --flash-bin "${MYIR_KERNEL_CONTAINER_FLASH_BIN}" \
            --container-offset "$cntr_offset" \
            --signature-offset "$sig_offset"

        if [ $? -ne 0 ]; then
            bbwarn "CSF generation failed for $dtb_basename"
            continue
        fi
        bbnote "  CSF: $staging/$csf_name"

        # ----------------------------------------------------------------
        # Step 6: Sign with NXP CST (running from staging directory)
        #
        # CST resolves relative paths against CWD:
        #   - crts/  -> certs directory (symlink)
        #   - keys/  -> keys directory (symlink)
        #   - flash_os.bin -> kernel container (local file)
        #
        # Output: os_cntr_signed.bin in staging directory.
        # ----------------------------------------------------------------
        signed_staging="$staging/$signed_name"

        bbnote "  Signing kernel container with CST (from $staging/)..."
        cd "$staging"

        ${MYIR_AHAB_CST_BIN} ${MYIR_AHAB_CST_ARGS} -i "$csf_name" -o "$signed_name"
        cst_ret=$?
        cd - > /dev/null

        if [ $cst_ret -ne 0 ]; then
            bbwarn "CST signing failed for $dtb_basename (exit code: $cst_ret)"
            continue
        fi

        if [ ! -f "$signed_staging" ]; then
            bbwarn "Signed output not produced: $signed_staging"
            continue
        fi

        bbnote "  -> Signed: $signed_name ($(stat -c%s "$signed_staging") bytes)"

        # ----------------------------------------------------------------
        # Step 7: Copy signed binary to WORKDIR for deploy
        # ----------------------------------------------------------------
        cp "$signed_staging" "${WORKDIR}/$signed_name"
        bbnote "  -> Copied to WORKDIR for deploy"
    done

    if [ $dtb_count -eq 0 ]; then
        bbwarn "No valid DTBs found for kernel container signing"
        bbwarn "Check MYIR_KERNEL_CONTAINER_DTBS and DEPLOY_DIR_IMAGE"
    else
        bbnote "Kernel container signing complete: $dtb_count DTB(s) processed"
    fi

    bbnote "============================================"
}

# Run after do_ahab_sign (boot container signed), before do_install.
# Depends on virtual/kernel:do_deploy for Image and DTB files.
addtask do_sign_kernel_container after do_ahab_sign before do_install
do_sign_kernel_container[depends] += "virtual/kernel:do_deploy"

# ==========================================================================
# Deploy signed kernel containers
#
# os_cntr_signed*.bin files are deployed alongside boot images.
# U-Boot's boot scripts reference these to load and authenticate
# the kernel via ELE AHAB verification.
# ==========================================================================

do_deploy:append:mx95-generic-bsp() {
    if [ "${MYIR_KERNEL_CONTAINER_ENABLE}" = "1" ]; then
        install -d ${DEPLOYDIR}
        bbnote "Deploying signed kernel containers..."
        for signed in ${WORKDIR}/${MYIR_KERNEL_CONTAINER_SIGNED_PREFIX}*.bin; do
            if [ -f "$signed" ]; then
                install -m 0644 "$signed" ${DEPLOYDIR}/
                bbnote "  Deployed: $(basename $signed)"
            fi
        done

        # Also deploy CSF files for audit / debugging
        for csf in ${WORKDIR}/csf_linux_img*.csf; do
            if [ -f "$csf" ]; then
                install -m 0644 "$csf" ${DEPLOYDIR}/
            fi
        done

        # Deploy signed boot containers (unsigned preserved by base recipe)
        bbnote "Deploying signed boot containers..."
        for signed_boot in ${S}/imx-boot*-${MACHINE}*.signed; do
            if [ -f "$signed_boot" ]; then
                install -m 0644 "$signed_boot" ${DEPLOYDIR}/
                bbnote "  Deployed: $(basename $signed_boot)"
            fi
        done


        # Create imx-boot-signed symlink pointing to AHAB-signed variant
        # The base recipe creates imx-boot -> unsigned binary; this adds
        # imx-boot-signed -> same binary with AHAB signature
        if [ ! -f "${DEPLOYDIR}/imx-boot-signed" ]; then
            if [ -L "${DEPLOYDIR}/imx-boot" ]; then
                unsigned_target=$(readlink "${DEPLOYDIR}/imx-boot")
                if [ -n "$unsigned_target" ] && [ -f "${DEPLOYDIR}/${unsigned_target}.signed" ]; then
                    ln -sf ${unsigned_target}.signed ${DEPLOYDIR}/imx-boot-signed
                    bbnote "Created imx-boot-signed -> ${unsigned_target}.signed"
                else
                    bbwarn "Signed boot binary not found for imx-boot: ${unsigned_target}.signed"
                    bbwarn "You may need to check AHAB signing configuration"
                fi
            else
                bbwarn "imx-boot symlink not found, skipping imx-boot-signed"
            fi
        fi

        # Deploy SRK fuse burning commands
        if [ -f "${WORKDIR}/fuse-cmds.txt" ]; then
            install -m 0644 "${WORKDIR}/fuse-cmds.txt" ${DEPLOYDIR}/
            bbnote "  Deployed: fuse-cmds.txt"
        fi
    fi
}

# Also copy CSF files from staging to WORKDIR for deploy
# (generated in staging for CST, but deployed from WORKDIR)
do_sign_kernel_container:append() {
    if [ "${MYIR_KERNEL_CONTAINER_ENABLE}" = "1" ]; then
        staging="${S}/${IMX_BOOT_SOC_TARGET}"
        for csf in "$staging"/csf_linux_img*.csf; do
            if [ -f "$csf" ]; then
                cp "$csf" "${WORKDIR}/"
            fi
        done
    fi
}
