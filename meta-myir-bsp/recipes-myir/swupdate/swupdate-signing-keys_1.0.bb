SUMMARY = "SWUpdate signing keys for MYD-JS8MPQ"
DESCRIPTION = "Deploy a layer-provided RSA key set or generate a development fallback"
LICENSE = "CLOSED"

inherit deploy

FILESEXTRAPATHS:prepend := "${THISDIR}/swupdate:"
S = "${UNPACKDIR}"

DEPENDS = "openssl-native"
PACKAGE_ARCH = "${MACHINE_ARCH}"
COMPATIBLE_MACHINE = "^myd-js8mpq$"

SWUPDATE_RSA_BITS ?= "2048"
SWUPDATE_AUTO_GENERATE_KEYS ?= "1"
SWUPDATE_LAYER_KEYS_AVAILABLE = "0"

python __anonymous() {
    import os

    keydir = os.path.join(d.getVar("THISDIR"), "swupdate")
    keyfiles = ("priv.pem", "priv.password", "swu_public.pem")
    present = [os.path.isfile(os.path.join(keydir, name)) for name in keyfiles]

    if any(present) and not all(present):
        missing = [name for name, exists in zip(keyfiles, present) if not exists]
        bb.fatal("Incomplete layer SWUpdate key set in %s; missing: %s" %
                 (keydir, ", ".join(missing)))

    if all(present):
        d.setVar("SWUPDATE_LAYER_KEYS_AVAILABLE", "1")
        d.appendVar("SRC_URI", " " + " ".join("file://%s" % name for name in keyfiles))
}

do_compile[noexec] = "1"
do_install[noexec] = "1"

do_deploy() {
    keydir="${DEPLOYDIR}/swupdate-keys"
    deployed_keydir="${SWUPDATE_KEY_DEPLOY_DIR}"
    derived_public="$keydir/derived-public.der"
    supplied_public="$keydir/supplied-public.der"

    install -d -m 0700 "$keydir"
    umask 077

    if [ "${SWUPDATE_LAYER_KEYS_AVAILABLE}" = "1" ]; then
        bbnote "Using layer-provided SWUpdate signing keys"
        install -m 0600 "${UNPACKDIR}/priv.pem" "$keydir/priv.pem"
        install -m 0600 "${UNPACKDIR}/priv.password" "$keydir/priv.password"
        install -m 0644 "${UNPACKDIR}/swu_public.pem" "$keydir/swu_public.pem"
    elif [ -s "$deployed_keydir/priv.pem" ] && \
       [ -s "$deployed_keydir/priv.password" ] && \
       [ -s "$deployed_keydir/swu_public.pem" ]; then
        bbnote "Reusing deployed SWUpdate signing keys"
        install -m 0600 "$deployed_keydir/priv.pem" "$keydir/priv.pem"
        install -m 0600 "$deployed_keydir/priv.password" "$keydir/priv.password"
        install -m 0644 "$deployed_keydir/swu_public.pem" "$keydir/swu_public.pem"
    elif [ -e "$deployed_keydir/priv.pem" ] || \
         [ -e "$deployed_keydir/priv.password" ] || \
         [ -e "$deployed_keydir/swu_public.pem" ]; then
        bbfatal "Incomplete SWUpdate key set in $deployed_keydir"
    elif [ "${SWUPDATE_AUTO_GENERATE_KEYS}" = "1" ]; then
        bbwarn "Generating a development SWUpdate key set in $deployed_keydir"
        "${STAGING_BINDIR_NATIVE}/openssl" rand -hex \
            -out "$keydir/priv.password" 32
        "${STAGING_BINDIR_NATIVE}/openssl" genrsa -aes256 \
            -passout "file:$keydir/priv.password" \
            -out "$keydir/priv.pem" "${SWUPDATE_RSA_BITS}"
        "${STAGING_BINDIR_NATIVE}/openssl" rsa \
            -passin "file:$keydir/priv.password" \
            -in "$keydir/priv.pem" \
            -out "$keydir/swu_public.pem" -outform PEM -pubout
    else
        bbfatal "No SWUpdate signing keys found and SWUPDATE_AUTO_GENERATE_KEYS is disabled"
    fi

    # Verify the password, private key, public-key syntax, and key pairing
    # before either signing or installing the public key into the rootfs.
    "${STAGING_BINDIR_NATIVE}/openssl" pkey \
        -passin "file:$keydir/priv.password" \
        -in "$keydir/priv.pem" -pubout -outform DER \
        -out "$derived_public" || bbfatal "Invalid SWUpdate private key or password"
    "${STAGING_BINDIR_NATIVE}/openssl" pkey \
        -pubin -in "$keydir/swu_public.pem" -outform DER \
        -out "$supplied_public" || bbfatal "Invalid SWUpdate public key"
    cmp -s "$derived_public" "$supplied_public" || \
        bbfatal "SWUpdate private and public keys do not match"
    rm -f "$derived_public" "$supplied_public"

    chmod 0600 "$keydir/priv.pem" "$keydir/priv.password"
    chmod 0644 "$keydir/swu_public.pem"
}

addtask deploy after do_compile before do_build
