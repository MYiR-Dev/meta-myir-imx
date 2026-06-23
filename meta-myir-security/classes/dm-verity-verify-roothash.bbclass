# SPDX-License-Identifier: MIT
#
# dm-verity-verify-roothash.bbclass
# Root hash RSA signing for dm-verity images
#
# Based on NXP meta-security-imx-dmverity (lf-6.18.y-1.0.0)
#
# Overrides process_verity() from dm-verity-img.bbclass
# because the original has an early "return" (SEPARATE_HASH=0)
# that prevents :append from executing.
# We inject MYIR feature flags and RSA root hash signing
# BEFORE that return statement.

# Full override of process_verity() from dm-verity-img.bbclass
# with MYIR additions injected at the right point.
process_verity() {
    local ENV="${STAGING_VERITY_DIR}/${DM_VERITY_IMAGE}.$TYPE.verity.env"
    local WKS_INC="${STAGING_VERITY_DIR}/${DM_VERITY_IMAGE}.$TYPE.wks.in"
    rm -f $ENV

    # Each line contains a key and a value string delimited by ':'. Read the
    # two parts into separate variables and process them separately. For the
    # key part: convert the names to upper case and replace spaces with
    # underscores to create correct shell variable names. For the value part:
    # just trim all white-spaces.
    IFS=":"
    while read KEY VAL; do
        printf '%s=%s\n' \
            "$(echo "$KEY" | tr '[:lower:]' '[:upper:]' | sed 's/ /_/g')" \
            "$(echo "$VAL" | tr -d ' \t')" >> $ENV
    done

    # Add partition size
    echo "DATA_SIZE=$SIZE" >> $ENV

    # Add whether we are storing the hash data separately
    echo "SEPARATE_HASH=${DM_VERITY_SEPARATE_HASH}" >> $ENV

    # === MYIR additions: inject BEFORE the SEPARATE_HASH return ===
    echo "MYIR_OVERLAY=${MYIR_DM_VERITY_OVERLAY}" >> ${ENV}
    echo "MYIR_SIGN_ROOTHASH=${MYIR_DM_VERITY_SIGN_ROOTHASH}" >> ${ENV}

    # RSA root hash signing (NXP-style)
    if [ "${MYIR_DM_VERITY_SIGN_ROOTHASH}" = "1" ]; then
        local private_key="${STAGING_VERITY_DIR}/private_key.pem"
        local public_key="${STAGING_VERITY_DIR}/public_key.pem"
        local rh="${STAGING_VERITY_DIR}/roothash.txt"
        local rhs="${STAGING_VERITY_DIR}/roothash.sig"
        rm -f $private_key $public_key $rh $rhs

        # Create RSA private key
        openssl genrsa -out $private_key 2048

        # Fetch public key from the generated private key
        openssl rsa -in $private_key -pubout -out $public_key

        # Store roothash in a file and sign it
        root_hash=$(grep ^ROOT_HASH $ENV | sed 's/ROOT_HASH=//')
        echo ${root_hash} | tr -d '\n' > $rh
        openssl dgst -sha256 -sign $private_key -out $rhs $rh
    fi

    # === End MYIR additions ===

    # Configured for single partition use of veritysetup?  OK, we are done.
    if [ ${DM_VERITY_SEPARATE_HASH} -eq 0 ]; then
        return
    fi

    # Craft up the UUIDs that are part of the verity standard for root & hash
    # while we are here and in shell.  Re-read our output to get ROOT_HASH
    # and then cut it in 1/2 ; HI for data UUID and LO for hash-data UUID.
    # https://uapi-group.org/specifications/specs/discoverable_partitions_specification/

    ROOT_HASH=$(cat $ENV | grep ^ROOT_HASH | sed 's/ROOT_HASH=//' | tr a-f A-F)
    ROOT_HI=$(echo "obase=16;ibase=16;$ROOT_HASH/2^80" | bc)
    ROOT_LO=$(echo "obase=16;ibase=16;$ROOT_HASH%2^80" | bc)

    # Hyphenate as per UUID spec and as expected by wic+sgdisk parameters.
    ROOT_UUID=$(echo 00000000$ROOT_HI | sed 's/.*\(.\{32\}\)$/\1/' | \
        sed 's/./-&/9;s/./-&/14;s/./-&/19;s/./-&/24' | tr A-F a-f )
    RHASH_UUID=$(echo 00000000$ROOT_LO | sed 's/.*\(.\{32\}\)$/\1/' | \
        sed 's/./-&/9;s/./-&/14;s/./-&/19;s/./-&/24' | tr A-F a-f )

    # Emit the values needed for a veritysetup run in the initramfs
    echo "ROOT_UUID=$ROOT_UUID" >> $ENV
    echo "RHASH_UUID=$RHASH_UUID" >> $ENV

    # Create wks.in fragment with build specific UUIDs for partitions.
    echo 'part / --source rawcopy --ondisk sda --sourceparams="file=${DM_VERITY_DEPLOY_DIR}/${DM_VERITY_IMAGE}-${MACHINE}${IMAGE_NAME_SUFFIX}.${DM_VERITY_IMAGE_TYPE}.verity" --part-name verityroot --part-type="${DM_VERITY_ROOT_GUID}"'" --uuid=\"$ROOT_UUID\"" > $WKS_INC

    # note: no default mount point for hash data partition
    echo 'part --source rawcopy --ondisk sda --sourceparams="file=${DM_VERITY_DEPLOY_DIR}/${DM_VERITY_IMAGE}-${MACHINE}${IMAGE_NAME_SUFFIX}.${DM_VERITY_IMAGE_TYPE}.vhash" --part-name verityhash --part-type="${DM_VERITY_RHASH_GUID}"'" --uuid=\"$RHASH_UUID\"" >> $WKS_INC
}
