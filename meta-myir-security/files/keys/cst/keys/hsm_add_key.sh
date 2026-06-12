#!/bin/bash

#-----------------------------------------------------------------------------
#
# File: hsm_add_key.sh
#
# Description: This script adds a key to an existing HAB/AHAB PKI tree to be
#              used with the HAB/AHAB code signing feature.  Both the private
#              key and corresponding certificate are generated.  This script
#              can generate new SRKs, CSF keys and Images keys for HAB4 and
#              SRKs and SGKs for AHAB.
#              This script is not intended for generating CA root keys.
#
#            Copyright 2021-2023 NXP
#
#
#-----------------------------------------------------------------------------

stty erase 

if [ $# -gt 0 ]; then
    interactive="n"
else
    interactive="y"
fi

usage()
{
    echo
    echo "Usage:"
    echo "Interactive Mode:"
    echo "$0"
    echo
    echo "Command Line Mode:"
    echo "$0 -ver <4/a> -key-name <new key name> -id <new key object id> -kt <ecc/rsa> -kl <key length> [-md <message digest>] -duration <years> -srk <y/n> [-srk-ca <y/n>] -signing-key-label <CA/SRK signing key label> -signing-crt <CA/SRK signing cert>"
    echo "Options:"
    echo "    -kl: -kt = ecc then Supported key lengths: p256, p384, p521"
    echo "       : -kt = rsa then Supported key lengths: 2048, 3072, 4096"
    echo "    -md: -ver = a then Supported message digests: sha256, sha384, sha512"
    echo "       : -ver = 4 then md = sha256 is fixed"
    echo
    echo "$0 -h | --help : This text"
    echo
}

max_param=22
min_param=18
num_param=1

# Check USR_PIN is defined, if not then set default
if [[ -v "${USR_PIN}" || -z "${USR_PIN}" ]]
then
    USR_PIN=123456
fi

# Throw error if PKCS11_MODULE_PATH undefined
if [[ -v "${PKCS11_MODULE_PATH}" || -z "${PKCS11_MODULE_PATH}" ]]
then
    echo "ERROR: PKCS11_MODULE_PATH must be set"
    echo
    exit 1
fi

if [ "$interactive" = "n" ]
then
    # Validate command line parameters
    if [ "$1" = "-h" ] || [ "$1" =  "--help" ]
    then
        usage
        exit 0
    elif [ $# -lt $min_param ] || [ $# -gt $max_param ]
    then
        echo "ERROR: Correct parameters required in non-interactive mode"
        usage
        exit 1
    fi

    # Process command line inputs
    while [ $num_param -le $max_param ] && [ "$1" != "" ]
    do
        case $1 in
            -ver)
                shift
                ver=$1
                shift
                ;;
            -key-name)
                shift
                key_name=$1
                shift
                ;;
            -id)
                shift
                id=$1
                shift
                ;;
            -kt)
                shift
                kt=$1
                shift
                ;;
            -kl)
                shift
                kl=$1
                shift
                ;;
            -md)
                if [ "$ver" = "4" ]
                then
                    echo "ERROR: Message digest is fixed for HAB4"
                    usage
                    exit 1
                fi
                shift
                md=$1
                shift
                ;;
            -duration)
                shift
                duration=$1
                shift
                ;;
            -srk)
                shift
                srk=$1
                shift
                if [ "$srk" = "y" ] && [ "$1" != "-srk-ca" ]
                then
                    echo "ERROR: SRK CA option required when SRK is selected"
                    usage
                    exit 1
                fi
                ;;
            -srk-ca)
                shift
                srk_ca=$1
                shift
                ;;
            -signing-key-label)
                shift
                signing_key_label=$1
                shift
                ;;
            -signing-crt)
                shift
                signing_crt=$1
                shift
                ;;
            *)
                echo "ERROR: Invalid parameter: $1"
                usage
                exit 1
                ;;
        esac
        num_param=$(( num_param + 2 ))
    done
fi # interactive=n

if [ $(uname -m) = "x86_64" ]
then
    bin_path="linux64/bin"
else
    bin_path="linux32/bin"
fi

if [ "$interactive" = "y" ]
then
    printf "Which version of HAB/AHAB do you want to generate the key for (4 = HAB4 / a = AHAB)?:  \b"
    read ver
fi

case $ver in
    4) ;;
    a) ;;
    *)
        echo Error - HAB/AHAB version selected must be either 4 or a
   usage
   exit 1
esac

if [ "$interactive" = "y" ]
then
    printf "Enter new key name (e.g. SRK5):  \b"
    read key_name
fi

if [ "$interactive" = "y" ]
then
    printf "Enter new key object id (e.g. 1001):  \b"
    read id
fi

if [ $ver = "4" ] || [ $ver = "a" ]
then
    if [ "$interactive" = "y" ]
    then
        printf "Enter new key type (ecc / rsa):  \b"
        read kt
    fi

    # Confirm that a valid key type has been entered
    case $kt in
        rsa) ;;
        ecc) ;;
        *)
            echo Invalid key type. Supported key types: rsa, ecc
        usage
        exit 1 ;;
    esac
fi

if [ $kt = "rsa" ]
then
    if [ "$interactive" = "y" ]
    then
        printf "Enter new key length in bits:  \b"
        read kl
    fi

    # Confirm that a valid key length has been entered
    case $kl in
        2048) ;;
        3072) ;;
        4096) ;;
        *)
            echo Invalid key length. Supported key lengths: 2048, 3072, 4096
        usage
        exit 1 ;;
    esac
else
    if [ "$interactive" = "y" ]
    then
        printf "Enter new key length (p256 / p384 / p521):  \b"
        read kl
    fi

    # Confirm that a valid key length has been entered
    case $kl in
        p256)
            cn="prime256v1" ;;
        p384)
            cn="secp384r1" ;;
        p521)
            cn="secp521r1" ;;
        *)
            echo Invalid key length. Supported key lengths: 256, 384, 521
        usage
        exit 1 ;;
    esac
fi

if [ $ver = "a" ]
then
    if [ "$interactive" = "y" ]
    then
        printf "Enter new message digest (sha256, sha384, sha512):  \b"
        read md
    fi

    # Confirm that a valid message digest has been entered
    case $md in
        sha256) ;;
        sha384) ;;
        sha512) ;;
        *)
            echo Invalid message digest. Supported message digests: sha256, sha384, sha512
        usage
        exit 1 ;;
    esac
# HAB4
else
    md="sha256"
fi

if [ "$interactive" = "y" ]
then
    printf "Enter certificate duration (years):  \b"
    read duration
fi

# Compute validity period
val_period=$((duration*365))

# ---------------- Add SRK Key and Certificate -------------------
if [ "$interactive" = "y" ]
then
    printf "Is this an SRK key?:  \b"
    read srk
fi

if [ $srk = "y" ]
then
    # Check if SRKs should be generated as CA certs or user certs
    if [ $ver = "4" ] || [ $ver = "a" ]
    then
        if [ "$interactive" = "y" ]
        then
            printf "Do you want the SRK to have the CA flag set (y/n)?:  \b"
            read srk_ca
        fi

        if [ $srk_ca = "y" ]
        then
            ca="ca"
        else
            ca="usr"
        fi
    fi

    if [ "$interactive" = "y" ]
    then
        printf "Enter CA signing key label:  \b"
        read signing_key_label
        printf "Enter CA signing certificate name:  \b"
        read signing_crt
    fi
# Not SRK
else
    ca="usr"
    if [ $ver = "4" ] || [ $ver = "a" ]
    then
        if [ "$interactive" = "y" ]
        then
            # ------------ Add CSF/IMG/SGK Key and Certificate ---------------
            printf "Enter SRK signing key label:  \b"
            read signing_key_label
            printf "Enter SRK signing certificate name:  \b"
            read signing_crt
        fi
    fi
fi

# Check existance of keys/, crts/ and ca/ directories of <cst> before generating keys and
# switch current working directory to <cst>/keys directory, if needed.
crt_dir=$(pwd)
script_name=$(readlink "$0")
if [ "${script_name}" = "" ]
then
	script_name=$0
fi
script_path=$(cd $(dirname "${script_name}") && pwd -P)
keys_dir=${script_path}/../keys/
crts_dir=${script_path}/../crts/
ca_dir=${script_path}/../ca/

if [ ! -d "${keys_dir}" ]
then
    echo ERROR: "Private keys directory ${keys_dir} is missing. Expecting script to be located inside <cst>/keys directory."
    exit 1
fi

if [ ! -d "${crts_dir}" ]
then
    echo ERROR: "Public keys directory ${crts_dir} is missing. Expecting <cst>/crts directory to be already created."
    exit 1 
fi

if [ ! -d "${ca_dir}" ]
then
    echo ERROR: "Openssl configuration directory ${ca_dir} is missing. Expecting <cst>/ca directory to hold openssl configuration files."
    exit 1 
fi

# Switch current working directory to keys directory, if needed.
if [ "${crt_dir}" != "${keys_dir}" ]
then
    cd "${keys_dir}" 
    if [ $? -ge 1 ]
    then
        echo ERROR: "Cannot change directory to ${keys_dir}"
        exit 1
    fi 
fi

# Generate outputs
if [ $kt = "ecc" ]
then
    key_label=${key_name}_${md}_${cn}_v3_${ca}
    key_type=EC:${cn}
else
    key_label=${key_name}_${md}_${kl}_65537_v3_${ca}
    key_type=rsa:${kl}
fi

# # Generate Key
pkcs11-tool --module $PKCS11_MODULE_PATH -l \
    --pin $USR_PIN \
    --keypairgen \
    --key-type $key_type \
    --label $key_label \
    --id $id

# # Generate certificate signing request
openssl req -engine pkcs11 -new -batch \
    -subj "/CN=${key_label}/" \
    -keyform engine \
    -key "label_${key_label}" \
    -out ./${key_label}_req.pem \
    -passin pass:$USR_PIN

# # Generate certificate
openssl ca -engine pkcs11 -batch \
    -md ${md} -outdir ./ \
    -in ./${key_label}_req.pem \
    -cert "${signing_crt}" \
    -keyform engine \
    -keyfile "label_${signing_key_label}" \
    -extfile ../ca/v3_${ca}.cnf \
    -out "../crts/${key_label}_crt.pem" \
    -notext \
    -days ${val_period} \
    -config ../ca/openssl.cnf \
    -passin pass:$USR_PIN

# # Convert certificate to DER format
openssl x509 -outform DER \
    -in "../crts/${key_label}_crt.pem" \
    -out "../crts/${key_label}_crt.der"

# # Store DER certificate back to the HSM
pkcs11-tool --module $PKCS11_MODULE_PATH -l \
    --write-object "../crts/${key_label}_crt.der" \
    --type cert \
    --label ${key_label} \
    --pin $USR_PIN \
    --id $id

# Clean up
\rm -f *_req.pem

# Switch back to initial working directory, if needed.
if [ "${crt_dir}" != "${keys_dir}" ]
then
    cd "${crt_dir}" 
    if [ $? -ge 1 ]
    then
        echo ERROR: "Cannot change directory to ${crt_dir}"
        exit 1
    fi
fi
exit 0
