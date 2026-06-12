#!/bin/sh

#-----------------------------------------------------------------------------
#
# File: hab4_pki_tree.sh
#
# Description: This script generates a basic HAB4 PKI tree for the NXP
#              HAB code signing feature.  What the PKI tree looks like depends
#              on whether the SRK is chosen to be a CA key or not.  If the
#              SRKs are chosen to be CA keys then this script will generate the
#              following PKI tree:
#
#                                      CA Key
#                                      | | |
#                             -------- + | +---------------
#                            /           |                 \
#                         SRK1          SRK2       ...      SRKN
#                         / \            / \                / \
#                        /   \          /   \              /   \
#                   CSF1_1  IMG1_1  CSF2_1  IMG2_1 ... CSFN_1  IMGN_1
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
#              and not other keys.  Note that not all Freescale processors
#              including HAB support this option.
#
#        (c) Freescale Semiconductor, Inc. 2011, 2013. All rights reserved.
#        Copyright 2018-2022 NXP
#
#
#-----------------------------------------------------------------------------

printf "\n"
printf "    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
printf "    This script is a part of the Code signing tools for NXP's\n"
printf "    High Assurance Boot.  It generates a basic PKI tree.  The PKI\n"
printf "    tree consists of one or more Super Root Keys (SRK), with each\n"
printf "    SRK having two subordinate keys: \n"
printf "        + a Command Sequence File (CSF) key \n"
printf "        + Image key. \n"
printf "    Additional keys can be added to the PKI tree but a separate \n"
printf "    script is available for this.  This this script assumes openssl\n"
printf "    is installed on your system and is included in your search \n"
printf "    path.  Finally, the private keys generated are password \n"
printf "    protectedwith the password provided by the file key_pass.txt.\n"
printf "    The format of the file is the password repeated twice:\n"
printf "        my_password\n"
printf "        my_password\n"
printf "    All private keys in the PKI tree are in PKCS #8 format will be\n"
printf "    protected by the same password.\n\n"
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
    echo "$0 -existing-ca <y/n> [-ca-key <CA key name> -ca-cert <CA cert name>] -kt < rsa/rsa-pss/ecc> -kl <ECC Curve/RSA Key Length> -duration <years> -num-srk <1-4> -srk-ca <y/n>"
    echo "  Key Type Options:"
    echo "    -kl ecc     : then Supported key lengths: p256, p384, p521"
    echo "    -kl rsa     : then Supported key lengths: 1024, 2048, 3072, 4096"
    echo "    -kl rsa-pss : then Supported key lengths: 1024, 2048, 3072, 4096"
    echo
    echo "$0 -h | --help : This text"
    echo
}

max_param=16
min_param=12
num_param=1

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
                if [ "$existing_ca" = "y" ] && [ "$1" != "-ca-key" ]
                then
                    echo "ERROR: CA key is required."
                    usage
                    exit 1
                fi
                ;;
            -ca-key)
                shift
                ca_key=$1
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
            -duration)
                shift
                duration=$1
                shift
                ;;
            -num-srk)
                shift
                num_srk=$1
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
    printf "\n"
    printf "Key type options (confirm targeted device supports desired key type):\n"
    printf "Select the key type (possible values: rsa, rsa-pss, ecc)?:  \b"
    read kt
fi
case $kt in
    rsa)
        rsa_algo='rsa'
        use_ecc="n"
        use_rsa_pss="n" ;;
    rsa-pss)
        rsa_algo='rsa-pss'
        use_ecc="n"
        use_rsa_pss="y" ;;
    ecc)
        use_ecc="y" ;;
    *)
        echo Invalid key type selected
        exit 1 ;;
esac

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
else
    # Configure the RSA/RSA-PSS key length
    if [ "$interactive" = "y" ]
    then
        printf "Enter key length in bits for PKI tree:  \b"
        read kl
    fi

    # Confirm that a valid key length has been entered
    case $kl in
        1024) ;;
        2048) ;;
        3072) ;;
        4096) ;;
        *)
            echo Invalid key length. Supported key lengths: 1024, 2048, 3072, 4096
        usage
        exit 1 ;;
    esac
fi


if [ "$interactive" = "y" ]
then
    printf "Enter PKI tree duration (years):  \b"
    read duration
fi

# Compute validity period
val_period=$((duration*365))

if [ "$interactive" = "y" ]
then
    printf "How many Super Root Keys should be generated?  \b"
    read num_srk
fi

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

# Check that the file "key_pass.txt" is present, if not create it with default user/pwd:
if [ ! -f key_pass.txt ]
then
    echo "test" > key_pass.txt
    echo "test" >> key_pass.txt
    echo "A default file 'key_pass.txt' was created with password = test!"
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
        ca_key=./CA1_sha256_${kl}_65537_v3_ca_key
        ca_cert=../crts/CA1_sha256_${kl}_65537_v3_ca_crt
        ca_subj_req=/CN=CA1_sha256_${kl}_65537_v3_ca/
        ca_key_type=rsa:${kl}
    else

        # Generate Elliptic Curve parameters:
        eck='ec-'$cn'.pem'
        openssl ecparam -out $eck -name $cn

        ca_key=./CA1_sha256_${cn}_v3_ca_key
        ca_cert=../crts/CA1_sha256_${cn}_v3_ca_crt
        ca_subj_req=/CN=CA1_sha256_${cn}_v3_ca/
        ca_key_type=ec:${eck}
    fi

    openssl req -newkey ${ca_key_type} -passout file:./key_pass.txt \
                   -subj ${ca_subj_req} \
                   -x509 -extensions v3_ca \
                   -keyout temp_ca.pem \
                   -out ${ca_cert}.pem \
                   -days ${val_period} -config ../ca/openssl.cnf

    # Generate CA key in PKCS #8 format - both PEM and DER
    openssl pkcs8 -passin file:./key_pass.txt -passout file:./key_pass.txt \
                  -topk8 -inform PEM -outform DER -v2 des3 \
                  -in temp_ca.pem \
                  -out ${ca_key}.der

    openssl pkcs8 -passin file:./key_pass.txt -passout file:./key_pass.txt \
                  -topk8 -inform PEM -outform PEM -v2 des3 \
                  -in temp_ca.pem \
                  -out ${ca_key}.pem

    # Convert CA Certificate to DER format
    openssl x509 -inform PEM -outform DER -in ${ca_cert}.pem -out ${ca_cert}.der

    # Cleanup
    \rm temp_ca.pem $eck
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
            # Generate SRK key
            openssl genpkey -algorithm ${rsa_algo} -pkeyopt rsa_keygen_bits:${kl} \
                            -pass file:./key_pass.txt \
                            -out ./temp_srk.pem

            srk_subj_req=/CN=SRK${i}_sha256_${kl}_65537_v3_usr/
            srk_crt=../crts/SRK${i}_sha256_${kl}_65537_v3_usr_crt
            srk_key=./SRK${i}_sha256_${kl}_65537_v3_usr_key
        else
            # Generate Elliptic Curve parameters:
            openssl ecparam -out ./temp_srk.pem -name ${cn} -genkey
            # Generate SRK key
            openssl ec -in ./temp_srk.pem -des3 -passout file:./key_pass.txt \
                       -out ./temp_srk.pem

            srk_subj_req=/CN=SRK${i}_sha256_${cn}_v3_usr/
            srk_crt=../crts/SRK${i}_sha256_${cn}_v3_usr_crt
            srk_key=./SRK${i}_sha256_${cn}_v3_usr_key
        fi

        # Generate SRK certificate signing request
        openssl req -new -batch -passin file:./key_pass.txt \
                    -subj ${srk_subj_req} \
                    -key ./temp_srk.pem \
                    -out ./temp_srk_req.pem

        # Generate SRK certificate (this is a CA cert)
           openssl ca -batch -passin file:./key_pass.txt \
                      -md sha256 -outdir ./ \
                      -in ./temp_srk_req.pem \
                      -cert ${ca_cert}.pem \
                   -keyfile ${ca_key}.pem \
                      -extfile ../ca/v3_usr.cnf \
                      -out ${srk_crt}.pem \
                      -days ${val_period} \
                      -config ../ca/openssl.cnf

        # Convert SRK Certificate to DER format
        openssl x509 -inform PEM -outform DER \
                     -in ${srk_crt}.pem \
                     -out ${srk_crt}.der

        # Generate SRK key in PKCS #8 format - both PEM and DER
        openssl pkcs8 -passin file:./key_pass.txt \
                      -passout file:./key_pass.txt \
                      -topk8 -inform PEM -outform DER -v2 des3 \
                      -in temp_srk.pem \
                      -out ${srk_key}.der

        openssl pkcs8 -passin file:./key_pass.txt \
                      -passout file:./key_pass.txt \
                      -topk8 -inform PEM -outform PEM -v2 des3 \
                      -in temp_srk.pem \
                      -out ${srk_key}.pem

        # Cleanup
        \rm ./temp_srk.pem ./temp_srk_req.pem
        i=$((i+1))
    done
else

# Generate HAB  keys and certificates
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
            # Generate SRK key
            openssl genpkey -algorithm ${rsa_algo} -pkeyopt rsa_keygen_bits:${kl} \
                            -pass file:./key_pass.txt \
                            -out ./temp_srk.pem

            srk_subj_req=/CN=SRK${i}_sha256_${kl}_65537_v3_ca/
            srk_crt=../crts/SRK${i}_sha256_${kl}_65537_v3_ca_crt
            srk_key=./SRK${i}_sha256_${kl}_65537_v3_ca_key
        else
            # Generate Elliptic Curve parameters:
            openssl ecparam -out ./temp_srk.pem -name ${cn} -genkey
            # Generate SRK key
            openssl ec -in ./temp_srk.pem -des3 -passout file:./key_pass.txt \
                       -out ./temp_srk.pem

            srk_subj_req=/CN=SRK${i}_sha256_${cn}_v3_ca/
            srk_crt=../crts/SRK${i}_sha256_${cn}_v3_ca_crt
            srk_key=./SRK${i}_sha256_${cn}_v3_ca_key
    fi
    # Generate SRK certificate signing request
       openssl req -new -batch -passin file:./key_pass.txt \
                   -subj ${srk_subj_req} \
                   -key ./temp_srk.pem \
                   -out ./temp_srk_req.pem

    # Generate SRK certificate (this is a CA cert)
       openssl ca -batch -passin file:./key_pass.txt \
                  -md sha256 -outdir ./ \
                  -in ./temp_srk_req.pem \
                  -cert ${ca_cert}.pem \
                  -keyfile ${ca_key}.pem \
                  -extfile ../ca/v3_ca.cnf \
                  -out ${srk_crt}.pem \
                  -days ${val_period} \
                  -config ../ca/openssl.cnf

    # Convert SRK Certificate to DER format
    openssl x509 -inform PEM -outform DER \
                 -in ${srk_crt}.pem \
                 -out ${srk_crt}.der

    # Generate SRK key in PKCS #8 format - both PEM and DER
    openssl pkcs8 -passin file:./key_pass.txt \
                  -passout file:./key_pass.txt \
                  -topk8 -inform PEM -outform DER -v2 des3 \
                  -in temp_srk.pem \
                  -out ${srk_key}.der

    openssl pkcs8 -passin file:./key_pass.txt \
                  -passout file:./key_pass.txt \
                  -topk8 -inform PEM -outform PEM -v2 des3 \
                  -in temp_srk.pem \
                  -out ${srk_key}.pem

    # Cleanup
    \rm ./temp_srk.pem ./temp_srk_req.pem

    echo
    echo ++++++++++++++++++++++++++++++++++++++++
    echo + Generating CSF key and certificate $i +
    echo ++++++++++++++++++++++++++++++++++++++++
    echo

    if [ $use_ecc = 'n' ]
        then
            srk_crt_i=../crts/SRK${i}_sha256_${kl}_65537_v3_ca_crt.pem
            srk_key_i=./SRK${i}_sha256_${kl}_65537_v3_ca_key.pem
            # Generate key
            openssl genpkey -algorithm ${rsa_algo} -pkeyopt rsa_keygen_bits:${kl} \
                            -pass file:./key_pass.txt \
                            -out ./temp_csf.pem

            csf_subj_req=/CN=CSF${i}_1_sha256_${kl}_65537_v3_usr/
            csf_crt=../crts/CSF${i}_1_sha256_${kl}_65537_v3_usr_crt
            csf_key=./CSF${i}_1_sha256_${kl}_65537_v3_usr_key
        else
            srk_crt_i=../crts/SRK${i}_sha256_${cn}_v3_ca_crt.pem
            srk_key_i=./SRK${i}_sha256_${cn}_v3_ca_key.pem
            # Generate Elliptic Curve parameters:
            openssl ecparam -out ./temp_csf.pem -name ${cn} -genkey
            # Generate key
            openssl ec -in ./temp_csf.pem -des3 -passout file:./key_pass.txt \
                       -out ./temp_csf.pem

            csf_subj_req=/CN=CSF${i}_1_sha256_${cn}_v3_usr/
            csf_crt=../crts/CSF${i}_1_sha256_${cn}_v3_usr_crt
            csf_key=./CSF${i}_1_sha256_${cn}_v3_usr_key
    fi

    # Generate CSF certificate signing request
    openssl req -new -batch -passin file:./key_pass.txt \
                -subj ${csf_subj_req} \
                -key ./temp_csf.pem \
                -out ./temp_csf_req.pem

    # Generate CSF certificate (this is a user cert)
    openssl ca -batch -md sha256 -outdir ./ \
               -passin file:./key_pass.txt \
               -in ./temp_csf_req.pem \
               -cert ${srk_crt_i} \
               -keyfile ${srk_key_i} \
               -extfile ../ca/v3_usr.cnf \
               -out ${csf_crt}.pem \
               -days ${val_period} \
               -config ../ca/openssl.cnf

    # Convert CSF Certificate to DER format
    openssl x509 -inform PEM -outform DER \
                 -in ${csf_crt}.pem \
                 -out ${csf_crt}.der

    # Generate CSF key in PKCS #8 format - both PEM and DER
    openssl pkcs8 -passin file:./key_pass.txt -passout file:./key_pass.txt \
                  -topk8 -inform PEM -outform DER -v2 des3 \
                  -in temp_csf.pem \
                  -out ${csf_key}.der

    openssl pkcs8 -passin file:./key_pass.txt -passout file:./key_pass.txt \
                  -topk8 -inform PEM -outform PEM -v2 des3 \
                  -in temp_csf.pem \
                  -out ${csf_key}.pem

    # Cleanup
    \rm ./temp_csf.pem ./temp_csf_req.pem

    echo
    echo ++++++++++++++++++++++++++++++++++++++++
    echo + Generating IMG key and certificate $i +
    echo ++++++++++++++++++++++++++++++++++++++++
    echo

    if [ $use_ecc = 'n' ]
        then
            # Generate key
            openssl genpkey -algorithm ${rsa_algo} -pkeyopt rsa_keygen_bits:${kl} \
                            -pass file:./key_pass.txt \
                            -out ./temp_img.pem

            img_subj_req=/CN=IMG${i}_1_sha256_${kl}_65537_v3_usr/
            img_crt=../crts/IMG${i}_1_sha256_${kl}_65537_v3_usr_crt
            img_key=./IMG${i}_1_sha256_${kl}_65537_v3_usr_key
        else
            # Generate Elliptic Curve parameters:
            openssl ecparam -out ./temp_img.pem -name ${cn} -genkey
            # Generate key
            openssl ec -in ./temp_img.pem -des3 -passout file:./key_pass.txt \
                       -out ./temp_img.pem

            img_subj_req=/CN=IMG${i}_1_sha256_${cn}_v3_usr/
            img_crt=../crts/IMG${i}_1_sha256_${cn}_v3_usr_crt
            img_key=./IMG${i}_1_sha256_${cn}_v3_usr_key
    fi

    # Generate IMG certificate signing request
    openssl req -new -batch -passin file:./key_pass.txt \
                -subj ${img_subj_req} \
                -key ./temp_img.pem \
                -out ./temp_img_req.pem

    openssl ca -batch -md sha256 -outdir ./ \
               -passin file:./key_pass.txt \
               -in ./temp_img_req.pem \
               -cert ${srk_crt_i} \
               -keyfile ${srk_key_i} \
               -extfile ../ca/v3_usr.cnf \
               -out ${img_crt}.pem \
               -days ${val_period} \
               -config ../ca/openssl.cnf

    # Convert IMG Certificate to DER format
    openssl x509 -inform PEM -outform DER \
                 -in ${img_crt}.pem \
                 -out ${img_crt}.der

    # Generate IMG key in PKCS #8 format - both PEM and DER
    openssl pkcs8 -passin file:./key_pass.txt -passout file:./key_pass.txt \
                  -topk8 -inform PEM -outform DER -v2 des3 \
                  -in temp_img.pem \
                  -out ${img_key}.der

    openssl pkcs8 -passin file:./key_pass.txt -passout file:./key_pass.txt \
                  -topk8 -inform PEM -outform PEM -v2 des3 \
                  -in temp_img.pem \
                  -out ${img_key}.pem

    # Cleanup
    \rm ./temp_img.pem ./temp_img_req.pem

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
