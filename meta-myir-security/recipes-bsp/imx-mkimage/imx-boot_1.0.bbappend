# imx-boot_1.0.bbappend - AHAB Secure Boot Integration for i.MX95
#
# This bbappend adds AHAB signing support for i.MX9 processors.
# When MYIR_AHAB_ENABLE is set to "1", the generated flash.bin
# will be signed with the AHAB CSF using NXP CST tool.
#
# For i.MX95, the signing flow differs from i.MX8 HABv4:
#   1. imx-mkimage generates flash.bin (AHAB container format)
#   2. CST signs the entire flash.bin with AHAB CSF
#   3. The signed flash.bin is deployed
#
# Dependencies: myir-ahab.bbclass, NXP CST tool, generated keys

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Inherit AHAB signing class
inherit myir-kernel-container-sign

# Paths to security layer files.
# NOTE: Use absolute paths because LAYERDIR is not available in shell task
# context, and THISDIR may resolve incorrectly when multiple bbappends
# overlay the same recipe with modified FILESEXTRAPATHS.
MYIR_AHAB_SECURITY_LAYER = "${BSPDIR}/sources/meta-myir/meta-myir-security"
MYIR_AHAB_CSF_TEMPLATE   = "${MYIR_AHAB_SECURITY_LAYER}/recipes-bsp/imx-mkimage/files/mx95_ahab.csf.template"
MYIR_AHAB_GEN_CSF_SCRIPT = "${MYIR_AHAB_SECURITY_LAYER}/recipes-bsp/imx-mkimage/files/mx95_gen_csf.py"
MYIR_AHAB_GEN_FUSE_SCRIPT = "${MYIR_AHAB_SECURITY_LAYER}/recipes-bsp/imx-mkimage/files/gen_fuse_cmds.py"

# --------------------------------------------------------------------------
# Add AHAB signing as a separate task between do_compile and do_install
# do_compile generates flash.bin -> do_ahab_sign adds AHAB signature -> do_install
# --------------------------------------------------------------------------

do_ahab_sign() {
	# Only run if AHAB signing is enabled
	if [ "${MYIR_AHAB_ENABLE}" != "1" ]; then
		bbnote "AHAB signing disabled (MYIR_AHAB_ENABLE != 1), skipping"
		return 0
	fi

	# Only apply to mx95 family
	case "${SOC_FAMILY}" in
		mx95|mx943)
			bbnote "AHAB signing enabled for ${SOC_FAMILY}"
			;;
		*)
			bbnote "AHAB signing skipped for ${SOC_FAMILY} (only mx95/mx943 supported)"
			return 0
			;;
	esac

	bbnote "============================================"
	bbnote "AHAB Secure Boot Signing - i.MX95"
	bbnote "============================================"

	# Verify CST is available
	if [ ! -x "${MYIR_AHAB_CST_BIN}" ]; then
		bbfatal "CST binary not found: ${MYIR_AHAB_CST_BIN}"
		bbfatal "Please install NXP CST tool and set MYIR_CST_DIR"
	fi

	# Verify keys exist
	if [ ! -f "${MYIR_AHAB_CST_SRK}" ]; then
		bbfatal "SRK table not found: ${MYIR_AHAB_CST_SRK}"
		bbfatal "Please generate keys first. See meta-myir-security README."
	fi

	if [ ! -f "${MYIR_AHAB_CST_SRK_CERT}" ]; then
		bbfatal "SRK certificate not found: ${MYIR_AHAB_CST_SRK_CERT}"
	fi

	# Sign each generated boot binary
	for type in ${UBOOT_CONFIG}; do
		UBOOT_CONFIG_EXTRA="$type"
		BOOT_CONFIG_MACHINE_EXTRA="imx-boot${BOOT_VARIANT}-${MACHINE}-${UBOOT_CONFIG_EXTRA}.bin"

		# ==================================================================
		# PHASE 1: Sign the u-boot-atf-container.img (AHAB container #0)
		# This must be done ONCE before building any flash target.
		# The signed container is then embedded into each flash.bin.
		#
		# IMPORTANT: make must pass the same REV_OPTION and MKIMAGE_EXTRA_ARGS
		# as do_compile (REV=B0 OEI=YES LPDDR_TYPE=lpddr5 etc.), otherwise
		# the container layout will not match what the boot ROM expects.
		# ==================================================================
		if [ "${SOC_FAMILY}" = "mx9" ] || [ "${SOC_FAMILY}" = "mx95" ]; then
			atf_container="${S}/iMX95/u-boot-atf-container.img"
			if [ -f "$atf_container" ]; then
				bbnote "Signing AHAB container #0: u-boot-atf-container.img"

				# Extract ATF container offsets from the do_compile log.
				# The container was already built by do_compile; re-running
				# make would return "up to date" with an empty log.
				# Use head -1 to pick the ATF container's offsets (first
				# occurrence in the compile log, before any flash target).
				compile_log="${T}/log.do_compile"
				if [ -f "$compile_log" ]; then
					atf_header=$(grep "CST: CONTAINER 0 offset:" "$compile_log" | head -1 | awk '{print $5}')
					atf_block=$(grep "CST: CONTAINER 0: Signature Block" "$compile_log" | head -1 | awk '{print $9}')
				else
					atf_header=""
					atf_block=""
				fi
				bbnote "  u-boot-atf-container offsets: container=${atf_header:-0x0} signature=${atf_block:-0x190}"
				atf_csf="${S}/ahab_atf_container.csf"
				python3 ${MYIR_AHAB_GEN_CSF_SCRIPT} \
					"${MYIR_AHAB_CSF_TEMPLATE}" \
					"$atf_csf" \
					--srk-table "${MYIR_AHAB_CST_SRK}" \
					--srk-cert "${MYIR_AHAB_CST_SRK_CERT}" \
					--srk-source-idx "${MYIR_AHAB_CST_SRK_SOURCE_IDX}" \
					--flash-bin "$atf_container" \
					--container-offset "${atf_header:-0x0}" \
					--signature-offset "${atf_block:-0x190}"
				workdir=$(dirname "$atf_container")
				if [ ! -d "$workdir/keys" ]; then
					ln -sfn "${MYIR_AHAB_CST_KEYS_DIR}" "$workdir/keys"
				fi
				if [ ! -d "$workdir/crts" ]; then
					ln -sfn "${MYIR_AHAB_CST_CERTS_DIR}" "$workdir/crts"
				fi
				cd "$workdir"
				${MYIR_AHAB_CST_BIN} -i "$atf_csf" -o "${atf_container}-signed"
				ret=$?
				cd -
				if [ $ret -ne 0 ]; then
					bbfatal "CST signing failed for u-boot-atf-container.img (exit code: $ret)"
				fi
				mv -v "${atf_container}-signed" "$atf_container"
				bbnote "  -> Replaced $(basename $atf_container) with signed version (container #0)"
			fi
		fi

		# ==================================================================
		# PHASE 2: Build and sign each flash target
		# Each flash.bin embeds the already-signed ATF container from Phase 1.
		#
		# CRITICAL: make must use the EXACT SAME parameters as do_compile
		# (REV_OPTION + MKIMAGE_EXTRA_ARGS). Missing REV=B0 or OEI=YES
		# produces a flash.bin with wrong configuration that fails to boot.
		#
		# After make, flash.bin lives in ${S}/iMX95/flash.bin and must be
		# explicitly copied to $boot_bin before signing.
		# ==================================================================
		for target in ${IMXBOOT_TARGETS}; do
			boot_bin="${S}/${BOOT_CONFIG_MACHINE_EXTRA}-${target}"
			signed_bin="${S}/${BOOT_CONFIG_MACHINE_EXTRA}-${target}.signed"

			bbnote "Signing: $(basename $boot_bin)"

			# Build the flash target with signed ATF container,
			# using the exact same make parameters as do_compile
			if [ "${SOC_FAMILY}" = "mx9" ] || [ "${SOC_FAMILY}" = "mx95" ]; then
				flash_log="${WORKDIR}/mkimage-${target}.log"
				make -C ${S} SOC=${IMX_BOOT_SOC_TARGET} ${REV_OPTION} ${MKIMAGE_EXTRA_ARGS} dtbs=${UBOOT_DTB_NAME} ${target} > ${flash_log} 2>&1 || true

				# Copy the freshly-built flash.bin to the expected signing path.
				# Without this step, CST would sign the old flash.bin from
				# do_compile (which has an unsigned ATF container inside).
				flash_bin="${S}/iMX95/flash.bin"
				if [ -f "$flash_bin" ]; then
					cp "$flash_bin" "$boot_bin"
				else
					bbfatal "flash.bin not found after make ${target} (path: $flash_bin)"
				fi

				# Extract offsets directly from the mkimage log.
				# mkimage already computes and prints the correct AHAB
				# container + signature block offsets (no manual correction
				# needed — the "Offsets = ..." line confirms them).
				flash_header_seen=$(grep "CST: CONTAINER 0 offset:" ${flash_log} | tail -1 | awk '{print $5}')
				flash_block_seen=$(grep "CST: CONTAINER 0: Signature Block" ${flash_log} | tail -1 | awk '{print $9}')
				flash_header="${flash_header_seen:-0x8000}"
				flash_block="${flash_block_seen:-0x8310}"
				bbnote "  ${target} AHAB: container=${flash_header} signature=${flash_block}"
			else
				# Non-mx95: use default offsets from bbclass variables
				flash_header="${MYIR_AHAB_CONTAINER_HEADER_OFFSET}"
				flash_block="${MYIR_AHAB_SIGNATURE_BLOCK_OFFSET}"
			fi

			# Generate AHAB CSF for this binary using external Python script
			csf_file="${S}/ahab_${BOOT_CONFIG_MACHINE_EXTRA}_${target}.csf"

			python3 ${MYIR_AHAB_GEN_CSF_SCRIPT} \
				"${MYIR_AHAB_CSF_TEMPLATE}" \
				"$csf_file" \
				--srk-table "${MYIR_AHAB_CST_SRK}" \
				--srk-cert "${MYIR_AHAB_CST_SRK_CERT}" \
				--srk-source-idx "${MYIR_AHAB_CST_SRK_SOURCE_IDX}" \
				--flash-bin "$boot_bin" \
				--container-offset "${flash_header}" \
				--signature-offset "${flash_block}"

			if [ $? -ne 0 ]; then
				bbfatal "CSF generation failed for $boot_bin"
			fi

			bbnote "  CSF: $csf_file"

			# Create symlinks for CST (it expects keys/ and crts/ in working dir)
			workdir=$(dirname "$boot_bin")
			if [ ! -d "$workdir/keys" ]; then
				ln -sfn "${MYIR_AHAB_CST_KEYS_DIR}" "$workdir/keys"
			fi
			if [ ! -d "$workdir/crts" ]; then
				ln -sfn "${MYIR_AHAB_CST_CERTS_DIR}" "$workdir/crts"
			fi

			# Execute CST to sign
			cd "$workdir"
			${MYIR_AHAB_CST_BIN} ${MYIR_AHAB_CST_ARGS} -i "$csf_file" -o "$signed_bin"
			ret=$?
			cd -

			if [ $ret -ne 0 ]; then
				bbfatal "CST signing failed for $boot_bin (exit code: $ret)"
			fi

			if [ ! -f "$signed_bin" ]; then
				bbfatal "Signed output not generated: $signed_bin"
			fi

			# CST outputs <file>.signed alongside <file> (unsigned preserved)
			bbnote "  -> Unsigned: $(basename $boot_bin) (preserved)"
			bbnote "  -> Signed:   $(basename $signed_bin)"
		done

		unset UBOOT_CONFIG_EXTRA
		unset BOOT_CONFIG_MACHINE_EXTRA
	done



		# Generate SRK fuse burning commands for production OTP programming
		if [ -f "${MYIR_AHAB_CST_SRK_FUSE}" ]; then
			bbnote "Generating fuse burning commands..."
			python3 ${MYIR_AHAB_GEN_FUSE_SCRIPT} \
				"${MYIR_AHAB_CST_SRK_FUSE}" \
				"${WORKDIR}/fuse-cmds.txt"
			if [ $? -eq 0 ] && [ -f "${WORKDIR}/fuse-cmds.txt" ]; then
				bbnote "  -> Generated: fuse-cmds.txt"
			else
				bbwarn "Failed to generate fuse burning commands"
			fi
		fi
	bbnote "============================================"
	bbnote "AHAB signing completed successfully"
	bbnote "============================================"
}

# Run AHAB signing after compile, before install
addtask do_ahab_sign after do_compile before do_install
# Ensure deploy runs after all signing tasks complete.
# Base recipe has: addtask deploy before do_build after do_compile
# We need deploy to wait for do_install (-> do_sign_kernel_container -> do_ahab_sign)
addtask deploy before do_build after do_compile do_install

# --------------------------------------------------------------------------
# Conflict prevention: if MYIR_AHAB_ENABLE=1, disable UBOOT_SIGN_ENABLE
# to avoid the HABv4 two-pass flow conflicting with AHAB signing.
# The two signing methods are mutually exclusive:
#   - UBOOT_SIGN_ENABLE=1: HABv4 signing for i.MX8
#   - MYIR_AHAB_ENABLE=1 : AHAB signing for i.MX9/i.MX95
# --------------------------------------------------------------------------
python () {
    if d.getVar('MYIR_AHAB_ENABLE') == '1' and d.getVar('UBOOT_SIGN_ENABLE') == '1':
        bb.warn('Both MYIR_AHAB_ENABLE and UBOOT_SIGN_ENABLE are set to 1.')
        bb.warn('For i.MX95, use only MYIR_AHAB_ENABLE=1 (AHAB signing).')
        bb.warn('UBOOT_SIGN_ENABLE=1 uses HABv4 flow which is for i.MX8 only.')
        bb.warn('Setting UBOOT_SIGN_ENABLE=0 to avoid conflicts...')
        d.setVar('UBOOT_SIGN_ENABLE', '0')
}
