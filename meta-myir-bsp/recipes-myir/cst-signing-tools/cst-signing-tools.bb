# Description: Fetch CST v4.0.1, generate AHAB keys and SRK table with interactive inputs,
#              deploy artifacts for later U-Boot/ATF signing.

SUMMARY = "CST signing tools and keys for i.MX AHAB"
LICENSE = "BSD-3-Clause"
# Replace with actual MD5 sum of the LICENSE file in the CST source
LIC_FILES_CHKSUM = "file://COPYING;md5=dc56c17219895403ffc9aea66e228c8c"

SRC_URI = "git://github.com/MYiR-Dev/cst-tools.git;protocol=https;branch=lf-6.12.y-myd-lmx9x-11x11"
SRCREV = "7a8b5cabe59dc8731fdcd75906cca6cc2cd04ffc"

S = "${WORKDIR}/git"

DEPENDS = "openssl-native openssl"
inherit deploy

do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install[noexec] = "1"
PACKAGES = ""

# Generate keys and SRK table only once (unless manually cleaned)
do_generate_keys() {
    cd ${S}
    mkdir -p crts
    # Generate keys if root_key.pem does not exist (indicates first run)
    if [ ! -f keys/root_key.pem ]; then
        bbnote "Generating AHAB keys with ahab_pki_tree.sh (interactive inputs: n, ecc, p384, sha384, 5, n)..."
        cd keys
	# Command-line options:
        #   -existing-ca n   : do not use existing CA key
        #   -kt ecc          : key type ECC
        #   -kl p384         : curve P-384
        #   -da sha384       : digest algorithm SHA-384
        #   -duration 5      : validity 5 years
        #   -srk-ca n        : do not set CA flag on SRK certificates
        ./ahab_pki_tree.sh -existing-ca n -kt ecc -kl p384 -da sha384 -duration 5 -srk-ca n || {
            bbfatal "ahab_pki_tree.sh failed"
        }
        cd ..
    else
        bbnote "AHAB keys already exist, skipping generation."
    fi

    # Generate SRK table if not already present
    if [ ! -f crts/SRK_1_2_3_4_table.bin ]; then
        bbnote "Generating SRK table using srktool..."
        cd crts
        ../linux64/bin/srktool -a -d sha256 -s sha384 -t SRK_1_2_3_4_table.bin -e SRK_1_2_3_4_fuse.bin -f 1 -c SRK1_sha384_secp384r1_v3_usr_crt.pem,SRK2_sha384_secp384r1_v3_usr_crt.pem,SRK3_sha384_secp384r1_v3_usr_crt.pem,SRK4_sha384_secp384r1_v3_usr_crt.pem || {
            bbfatal "srktool failed"
        }
        cd ..
    else
        bbnote "SRK table already exists, skipping generation."
    fi
}

addtask generate_keys after do_patch before do_deploy

# Deploy all required artifacts to a single directory in DEPLOY_DIR_IMAGE
do_deploy() {
    deploy_dir="${DEPLOYDIR}/cst-signing"
    install -d ${deploy_dir}

    # Copy keys and certificates directories
    cp -r ${S}/keys ${S}/crts ${deploy_dir}/

    # Copy binary tools (cst and srktool)
    install -d ${deploy_dir}/linux64/bin
    cp ${S}/linux64/bin/cst ${S}/linux64/bin/srktool ${deploy_dir}/linux64/bin/
    chmod +x ${deploy_dir}/linux64/bin/*

    # Copy CSF template files (assumed to be in source root)
    cp ${S}/*.txt ${deploy_dir}/ 2>/dev/null || true

    bbnote "CST signing tools and keys deployed to ${deploy_dir}"
}

addtask deploy before do_build after do_generate_keys
