#!/bin/sh

#-----------------------------------------------------------------------------
#
# File: add_key.sh
#
# Description: This script adds a key to an existing HAB PKI tree to be used
#              with the HAB code signing feature.  Both the private key and
#              corresponding certificate are generated.  This script can
#              generate new SRKs, CSF keys and Images keys for HAB4 or AHAB.
#              This script is not intended for generating CA root keys.
#
#            (c) Freescale Semiconductor, Inc. 2011. All rights reserved.
#            Copyright 2018-2022 NXP
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
    echo "$0 -ver <4/a> -key-name <new key name> -kt <ecc/rsa/rsa-pss> -kl <key length> [-md <message digest>] -duration <years> -srk <y/n> [-srk-ca <y/n>] -signing-key <CA/SRK signing key> -signing-crt <CA/SRK signing cert>"
    echo "Options:"
    echo "    -kl: -kt = ecc then Supported key lengths: p256, p384, p521"
    echo "       : -kt = rsa then Supported key lengths: 1024, 2048, 3072, 4096"
    echo "       : -kt = rsa-pss then Supported key lengths: 1024, 2048, 3072, 4096"
    echo "    -md: -ver = a then Supported message digests: sha256, sha384, sha512"
    echo "       : -ver = 4 then md = sha256 is fixed"
    echo
    echo "$0 -h | --help : This text"
    echo
}

max_param=20
min_param=16
num_param=1

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
            -signing-key)
                shift
                signing_key=$1
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

if [ $ver = "4" ] || [ $ver = "a" ]
then
    if [ "$interactive" = "y" ]
    then
        printf "Enter new key type (ecc / rsa / rsa-pss):  \b"
        read kt
    fi
fi

# Confirm that a valid key type has been entered
case $kt in
    rsa) rsa_algo='rsa' ;;
    rsa-pss) rsa_algo='rsa-pss';;
    ecc) ;;
    *)
        echo Invalid key type. Supported key types: rsa, ecc
        usage
        exit 1 ;;
esac

if [ $kt = "rsa" ] || [ $kt = "rsa-pss" ]
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
            cn="secp256r1" ;;
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
        printf "Enter CA signing key name:  \b"
        read signing_key
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
            printf "Enter SRK signing key name:  \b"
            read signing_key
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
    key_fullname=${key_name}_${md}_${cn}_v3_${ca}

    # Generate Elliptic Curve parameters:
    openssl ecparam -out ./${key_fullname}_key.pem -name ${cn} -genkey
    # Generate ECC key
    openssl ec -in ./${key_fullname}_key.pem -des3 -passout file:./key_pass.txt \
        -out ./${key_fullname}_key.pem
else
    key_fullname=${key_name}_${md}_${kl}_65537_v3_${ca}

    # Generate RSA key
    openssl genpkey -algorithm ${rsa_algo} -pkeyopt rsa_keygen_bits:${kl} \
                    -pass file:./key_pass.txt -out ./${key_fullname}_key.pem
fi

# Generate certificate signing request
openssl req -new -batch -passin file:./key_pass.txt \
    -subj /CN=${key_fullname}/ \
    -key ./${key_fullname}_key.pem \
    -out ./${key_fullname}_req.pem

# Generate certificate
openssl ca -batch -passin file:./key_pass.txt \
    -md ${md} -outdir ./ \
    -in ./${key_fullname}_req.pem \
    -cert ${signing_crt} \
    -keyfile ${signing_key} \
    -extfile ../ca/v3_${ca}.cnf \
    -out ../crts/${key_fullname}_crt.pem \
    -days ${val_period} \
    -config ../ca/openssl.cnf

# Convert certificate to DER format
openssl x509 -inform PEM -outform DER \
    -in ../crts/${key_fullname}_crt.pem \
    -out ../crts/${key_fullname}_crt.der

# Generate key in PKCS #8 format - both PEM and DER
openssl pkcs8 -passin file:./key_pass.txt \
    -passout file:./key_pass.txt \
    -topk8 -inform PEM -outform DER -v2 des3 \
    -in ${key_fullname}_key.pem \
    -out ${key_fullname}_key.der

openssl pkcs8 -passin file:./key_pass.txt \
    -passout file:./key_pass.txt \
    -topk8 -inform PEM -outform PEM -v2 des3 \
    -in ${key_fullname}_key.pem \
    -out ${key_fullname}_key_tmp.pem

mv ${key_fullname}_key_tmp.pem ${key_fullname}_key.pem

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
