#!/bin/bash

#-----------------------------------------------------------------------------
#
# File: hsm_ahab_pki_tree.sh
#
# Description: This script generates a basic AHAB PKI tree for the NXP
#              AHAB code signing feature using HSM.  What the PKI tree looks like
#              depends on whether the SRK is chosen to be a CA key or not.  If the
#              SRKs are chosen to be CA keys then this script will generate the
#              following PKI tree:
#
#                                      CA Key
#                                      | | |
#                             -------- + | +---------------
#                            /           |                 \
#                         SRK1          SRK2       ...      SRKN
#                          |             |                   |
#                          |             |                   |
#                         SGK1          SGK2                SGKN
#
#              where: N can be 1 to 4.
#
#              Additional keys can be added to the tree separately.  In this
#              configuration SRKs may only be used to sign/verify other
#              keys/certificates
#
#              If the SRKs are chosen to be non-CA keys then this script will
#              generate the following PKI tree:
#
#                                      CA Key
#                                      | | |
#                             -------- + | +---------------
#                            /           |                 \
#                         SRK1          SRK2       ...      SRKN
#
#              In this configuration SRKs may only be used to sign code/data
#              and not other keys.  Note that not all NXP processors
#              including AHAB support this option.
#
#        Copyright 2021-2023 NXP
#
#
#-----------------------------------------------------------------------------

printf "\n"
printf "    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
printf "         ------ HSM based key and cert generation script ------    \n"
printf "    This script is a part of the Code signing tools for NXP's\n"
printf "    Advanced High Assurance Boot.  It generates a basic PKI tree. The\n"
printf "    PKI tree consists of one or more Super Root Keys (SRK), with each\n"
printf "    SRK having one subordinate keys: \n"
printf "        + a Signing key (SGK) \n"
printf "    Additional keys can be added to the PKI tree but a separate \n"
printf "    script is available for this.  This this script assumes openssl\n"
printf "    is installed on your system and is included in your search \n"
printf "    path. Finally, the private keys generated are PIN protected \n"
printf "    provided by the user during token initialization.\n"
printf "    All private keys in the PKI tree are protected by the PIN.\n\n"
printf "    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"

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
    echo "$0 -existing-ca <y/n> [-ca-key-label <CA key label> -ca-cert <CA cert name>] -use-ecc <y/n> -kl <ECC/RSA Key Length> -da <digest algorithm> -duration <years> -srk-ca <y/n>"
    echo "Options:"
    echo "    -kl: -use-ecc = y then Supported key lengths: p256, p384, p521"
    echo "       : -use-ecc = n then Supported key lengths: 2048, 3072, 4096"
    echo "    -da: Supported digest algorithms: sha256, sha384, sha512"
    echo
    echo "$0 -h | --help : This text"
    echo
}

max_param=16
min_param=12
num_param=1
id=1000

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

if [ $interactive = "n" ]
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
            -existing-ca)
                shift
                existing_ca=$1
                shift
                if [ "$existing_ca" = "y" ] && [ "$1" != "-ca-key-label" ]
                then
                    echo "ERROR: CA key is required."
                    usage
                    exit 1
                fi
                ;;
            -ca-key-label)
                shift
                ca_key_label=$1
                shift
                if [ "$existing_ca" = "y" ] && [ "$1" != "-ca-cert" ]
                then
                    echo "ERROR: CA cert is required."
                    usage
                    exit 1
                fi
                ;;
            -ca-cert)
                shift
                ca_cert=$1
                shift
                ;;
            -use-ecc)
                shift
                use_ecc=$1
                shift
                ;;
            -kl)
                shift
                kl=$1
                shift
                ;;
            -da)
                shift
                da=$1
                shift
                ;;
            -duration)
                shift
                duration=$1
                shift
                ;;
            -srk-ca)
                shift
                srk_ca=$1
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

if [ $interactive = "y" ]
then
    printf "Do you want to use an existing CA key (y/n)?:  \b"
    read existing_ca
    if [ $existing_ca = "y" ]
    then
        printf "Enter CA key name:  \b"
        read ca_key
        printf "Enter CA certificate name:  \b"
        read ca_cert
    fi
fi

if [ "$interactive" = "y" ]
then
    printf "Do you want to use Elliptic Curve Cryptography (y/n)?:  \b"
    read use_ecc
fi

if [ $use_ecc = "y" ]
then
    if [ "$interactive" = "y" ]
    then
        printf "Enter length for elliptic curve to be used for PKI tree:\n"
        printf "Possible values p256, p384, p521:   \b"
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
else
    if [ "$interactive" = "y" ]
    then
        printf "Enter key length in bits for PKI tree:  \b"
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
fi

if [ "$interactive" = "y" ]
then
    printf "Enter the digest algorithm to use:  \b"
    read da
fi

# Confirm that a valid digest algorithm has been entered
case $da in
    sha256) ;;
    sha384) ;;
    sha512) ;;
    *)
        echo Invalid digest algorithm. Supported digest algorithms: sha256, sha384, sha512
    usage
    exit 1 ;;
esac

if [ "$interactive" = "y" ]
then
    printf "Enter PKI tree duration (years):  \b"
    read duration
fi

# Compute validity period
val_period=$((duration*365))

# printf "How many Super Root Keys should be generated?  \b"
# read num_srk
num_srk=4

# Check that 0 < num_srk <= 4 (Max. number of SRKs)
if [ $num_srk -lt 1 ] || [ $num_srk -gt 4 ]
then
    echo The number of SRKs generated must be between 1 and 4
    usage
    exit 1
fi

if [ "$interactive" = "y" ]
then
    # Check if SRKs should be generated as CA certs or user certs
    printf "Do you want the SRK certificates to have the CA flag set? (y/n)?:  \b"
    read srk_ca
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

# Check that the file "serial" is present, if not create it:
if [ ! -f serial ]
then
    echo "12345678" > serial
    echo "A default 'serial' file was created!"
fi

# The following is required otherwise OpenSSL complains
if [ -f index.txt ]
then
    rm index.txt
fi
touch index.txt
echo "unique_subject = no" > index.txt.attr

if [ $existing_ca = "n" ]
then
    # Generate CA key and certificate
    # -------------------------------
    echo
    echo +++++++++++++++++++++++++++++++++++++
    echo + Generating CA key and certificate +
    echo +++++++++++++++++++++++++++++++++++++
    echo

    if [ $use_ecc = 'n' ]
    then
        ca_key_label=./CA1_${da}_${kl}_65537_v3_ca
        ca_cert=../crts/CA1_${da}_${kl}_65537_v3_ca_crt
        ca_subj_req=/CN=CA1_${da}_${kl}_65537_v3_ca/
        ca_key_type=rsa:${kl}
    else

        ca_key_label=./CA1_${da}_${cn}_v3_ca
        ca_cert=../crts/CA1_${da}_${cn}_v3_ca_crt
        ca_subj_req=/CN=CA1_${da}_${cn}_v3_ca/
        ca_key_type=EC:${cn}
    fi

    # # Generate CA Key
    pkcs11-tool --module $PKCS11_MODULE_PATH -l \
        --pin $USR_PIN \
        --keypairgen \
        --key-type $ca_key_type \
        --label $ca_key_label \
        --id $id

    # # Generate self-signed CA certificate
    openssl req -engine pkcs11 -new -batch \
        -${da} \
        -subj ${ca_subj_req} \
        -key "label_${ca_key_label}" \
        -keyform engine \
        -out ${ca_cert}.pem \
        -text -x509 -extensions v3_ca \
        -days ${val_period} \
        -config ../ca/openssl.cnf \
	-passin pass:$USR_PIN

    # # Convert CA Certificate to DER format
    openssl x509 -outform DER \
        -in ${ca_cert}.pem \
        -out ${ca_cert}.der
fi


if [ $srk_ca != "y" ]
then
    # Generate SRK keys and certificates (non-CA)
    #     SRKs suitable for signing code/data
    # -------------------------------------------
    i=1;  # SRK Loop index
    while [ $i -le $num_srk ]
    do
        echo
        echo ++++++++++++++++++++++++++++++++++++++++
        echo + Generating SRK key and certificate $i +
        echo ++++++++++++++++++++++++++++++++++++++++
        echo
        if [ $use_ecc = 'n' ]
        then
            srk_subj_req=/CN=SRK${i}_${da}_${kl}_65537_v3_usr/
            srk_crt=../crts/SRK${i}_${da}_${kl}_65537_v3_usr_crt
            srk_key_label=./SRK${i}_${da}_${kl}_65537_v3_usr
            srk_key_type=rsa:${kl}
        else
            srk_subj_req=/CN=SRK${i}_${da}_${cn}_v3_usr/
            srk_crt=../crts/SRK${i}_${da}_${cn}_v3_usr_crt
            srk_key_label=./SRK${i}_${da}_${cn}_v3_usr
            srk_key_type=EC:${cn}
        fi

        id=$((id + 1))
        # # Generate SRK key
        pkcs11-tool --module $PKCS11_MODULE_PATH -l \
            --pin $USR_PIN \
            --keypairgen \
            --key-type $srk_key_type \
            --label $srk_key_label \
            --id $id

        # # Generate SRK certificate signing request
        openssl req -engine pkcs11 -new -batch \
            -subj ${srk_subj_req} \
            -keyform engine \
            -key "label_${srk_key_label}" \
            -out temp_srk_req.pem \
	    -passin pass:$USR_PIN

        # # Generate SRK certificate (this is a CA cert)
        openssl ca -engine pkcs11 -batch \
            -md ${da} -outdir ./ \
            -in ./temp_srk_req.pem \
            -cert "${ca_cert}.pem" \
            -keyform engine \
            -keyfile "label_${ca_key_label}" \
            -extfile ../ca/v3_usr.cnf \
            -out "${srk_crt}.pem" \
            -notext \
            -days ${val_period} \
            -config ../ca/openssl.cnf \
	    -passin pass:$USR_PIN

        # # Convert SRK Certificate to DER format
        openssl x509 -outform DER \
            -in ${srk_crt}.pem \
            -out ${srk_crt}.der

        # # Store DER certificate back to the HSM
        pkcs11-tool --module $PKCS11_MODULE_PATH -l \
            --write-object ${srk_crt}.der \
            --type cert \
            --label $srk_key_label \
            --pin $USR_PIN \
            --id $id

        # Cleanup
        \rm ./temp_srk_req.pem
        i=$((i+1))
    done
else

# Generate AHAB  keys and certificates
# -----------------------------------
i=1;  # SRK Loop index
while [ $i -le $num_srk ]
do

    echo
    echo ++++++++++++++++++++++++++++++++++++++++
    echo + Generating SRK key and certificate $i +
    echo ++++++++++++++++++++++++++++++++++++++++
    echo

    if [ $use_ecc = 'n' ]
        then
            srk_subj_req=/CN=SRK${i}_${da}_${kl}_65537_v3_ca/
            srk_crt=../crts/SRK${i}_${da}_${kl}_65537_v3_ca_crt
            srk_key_label=./SRK${i}_${da}_${kl}_65537_v3_ca
            srk_key_type=rsa:${kl}
        else
            srk_subj_req=/CN=SRK${i}_${da}_${cn}_v3_ca/
            srk_crt=../crts/SRK${i}_${da}_${cn}_v3_ca_crt
            srk_key_label=./SRK${i}_${da}_${cn}_v3_ca
            srk_key_type=EC:${cn}
    fi

    id=$((id + 1))
    # # Generate SRK key
    pkcs11-tool --module $PKCS11_MODULE_PATH -l \
        --pin $USR_PIN \
        --keypairgen \
        --key-type $srk_key_type \
        --label $srk_key_label \
        --id $id

    # # Generate SRK certificate signing request
    openssl req -engine pkcs11 -new -batch \
        -subj ${srk_subj_req} \
        -keyform engine \
        -key "label_${srk_key_label}" \
        -out temp_srk_req.pem \
	-passin pass:$USR_PIN

    # # Generate SRK certificate (this is a CA cert)
    openssl ca -engine pkcs11 -batch \
        -md ${da} -outdir ./ \
        -in ./temp_srk_req.pem \
        -cert "${ca_cert}.pem" \
        -keyform engine \
        -keyfile "label_${ca_key_label}" \
        -extfile ../ca/v3_ca.cnf \
        -out "${srk_crt}.pem" \
        -notext \
        -days ${val_period} \
        -config ../ca/openssl.cnf \
	-passin pass:$USR_PIN

    # # Convert SRK Certificate to DER format
    openssl x509 -outform DER \
        -in ${srk_crt}.pem \
        -out ${srk_crt}.der

    # # Store DER certificate back to the HSM
    pkcs11-tool --module $PKCS11_MODULE_PATH -l \
        --write-object ${srk_crt}.der \
        --type cert \
        --label $srk_key_label \
        --pin $USR_PIN \
        --id $id

    # Cleanup
    \rm ./temp_srk_req.pem

    echo
    echo ++++++++++++++++++++++++++++++++++++++++
    echo + Generating SGK key and certificate $i +
    echo ++++++++++++++++++++++++++++++++++++++++
    echo

    if [ $use_ecc = 'n' ]
        then
            srk_crt_i=../crts/SRK${i}_${da}_${kl}_65537_v3_ca_crt
            srk_key_i_label=./SRK${i}_${da}_${kl}_65537_v3_ca

            sgk_subj_req=/CN=SGK${i}_1_${da}_${kl}_65537_v3_usr/
            sgk_crt=../crts/SGK${i}_1_${da}_${kl}_65537_v3_usr_crt
            sgk_key_label=./SGK${i}_1_${da}_${kl}_65537_v3_usr
            sgk_key_type=rsa:${kl}
        else
            srk_crt_i=../crts/SRK${i}_${da}_${cn}_v3_ca_crt
            srk_key_i_label=./SRK${i}_${da}_${cn}_v3_ca

            sgk_subj_req=/CN=SGK${i}_1_${da}_${cn}_v3_usr/
            sgk_crt=../crts/SGK${i}_1_${da}_${cn}_v3_usr_crt
            sgk_key_label=./SGK${i}_1_${da}_${cn}_v3_usr
            sgk_key_type=EC:${cn}
    fi

    id=$((id + 1))
    # # Generate key
    pkcs11-tool --module $PKCS11_MODULE_PATH -l \
        --pin $USR_PIN \
        --keypairgen \
        --key-type $sgk_key_type \
        --label $sgk_key_label \
        --id $id

    # # Generate SGK certificate signing request
    openssl req -engine pkcs11 -new -batch \
        -subj ${sgk_subj_req} \
        -keyform engine \
        -key "label_${sgk_key_label}" \
        -out temp_sgk_req.pem \
	-passin pass:$USR_PIN

    # # Generate SGK certificate (this is a user cert)
    openssl ca -engine pkcs11 -batch \
        -md ${da} -outdir ./ \
        -in ./temp_sgk_req.pem \
        -cert "${srk_crt_i}.pem" \
        -keyform engine \
        -keyfile "label_${srk_key_i_label}" \
        -extfile ../ca/v3_usr.cnf \
        -out "${sgk_crt}.pem" \
        -notext \
        -days ${val_period} \
        -config ../ca/openssl.cnf \
	-passin pass:$USR_PIN

    # # Convert SGK Certificate to DER format
    openssl x509 -outform DER \
        -in ${sgk_crt}.pem \
        -out ${sgk_crt}.der

    # # Store DER certificate back to the HSM
    pkcs11-tool --module $PKCS11_MODULE_PATH -l \
      --write-object ${sgk_crt}.der \
      --type cert \
      --label $sgk_key_label \
      --pin $USR_PIN \
      --id $id

    # Cleanup
    \rm  ./temp_sgk_req.pem

    i=$((i+1))
done
fi

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
