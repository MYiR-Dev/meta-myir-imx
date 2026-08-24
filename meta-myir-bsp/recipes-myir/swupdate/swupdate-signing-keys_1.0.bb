SUMMARY = "Development SWUpdate signing keys for MYD-JS8MPQ"
DESCRIPTION = "Generate an encrypted RSA key and matching public key for development SWUpdate builds"
LICENSE = "CLOSED"

inherit deploy

DEPENDS = "openssl-native"
PACKAGE_ARCH = "${MACHINE_ARCH}"
COMPATIBLE_MACHINE = "^myd-js8mpq$"

SWUPDATE_RSA_BITS ?= "2048"

do_compile[noexec] = "1"
do_install[noexec] = "1"

do_deploy() {
    keydir="${DEPLOYDIR}/swupdate-keys"
    deployed_keydir="${SWUPDATE_KEY_DEPLOY_DIR}"

    install -d -m 0700 "$keydir"
    umask 077

    if [ -s "$deployed_keydir/priv.pem" ] && \
       [ -s "$deployed_keydir/priv.password" ] && \
       [ -s "$deployed_keydir/swu_public.pem" ]; then
        install -m 0600 "$deployed_keydir/priv.pem" "$keydir/priv.pem"
        install -m 0600 "$deployed_keydir/priv.password" "$keydir/priv.password"
        install -m 0644 "$deployed_keydir/swu_public.pem" "$keydir/swu_public.pem"
    elif [ -e "$deployed_keydir/priv.pem" ] || \
         [ -e "$deployed_keydir/priv.password" ] || \
         [ -e "$deployed_keydir/swu_public.pem" ]; then
        bbfatal "Incomplete SWUpdate key set in $deployed_keydir"
    else
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
    fi

    chmod 0600 "$keydir/priv.pem" "$keydir/priv.password"
    chmod 0644 "$keydir/swu_public.pem"
}

addtask deploy after do_compile before do_build
