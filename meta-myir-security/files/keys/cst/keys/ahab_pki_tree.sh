#!/bin/sh

#-----------------------------------------------------------------------------
#
# File: ahab_pki_tree.sh
#
# Description: This script generates a basic AHAB PKI tree for the NXP
#              AHAB code signing feature.  What the PKI tree looks like depends
#              on whether the SRK is chosen to be a CA key or not.  If the
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
#        Copyright 2018-2022, 2024 NXP
#
#
#-----------------------------------------------------------------------------

printf "\n"
printf "    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
printf "    This script is a part of the Code signing tools for NXP's\n"
printf "    Advanced High Assurance Boot.  It generates a basic PKI tree. The\n"
printf "    PKI tree consists of one or more Super Root Keys (SRK), with each\n"
printf "    SRK having one subordinate keys: \n"
printf "        + a Signing key (SGK) \n"
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
    echo "$0 -existing-ca <y/n> [-ca-key <CA key name> -ca-cert <CA cert name>] -kt <y/n> -kl <ECC/RSA Key Length> -da <digest algorithm> -duration <years> -srk-ca <y/n>"
    echo "Options:"
    echo "    -kt ecc     : then Supported key lengths: p256, p384, p521"
    echo "    -kt rsa     : then Supported key lengths: 2048, 3072, 4096"
    echo "    -kt rsa-pss : then Supported key lengths: 2048, 3072, 4096"
    echo "    -da: Supported digest algorithms: sha256, sha384, sha512"
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
        ca_key=./CA1_${da}_${kl}_65537_v3_ca_key
        ca_cert=../crts/CA1_${da}_${kl}_65537_v3_ca_crt
        ca_subj_req=/CN=CA1_${da}_${kl}_65537_v3_ca/

    if [ $use_rsa_pss = 'y' ]
    then
        ca_key_type=rsa-pss
    else
        ca_key_type=rsa
    fi
    openssl req -new \
        -newkey ${ca_key_type} \
        -keyout temp_ca.pem \
        -out temp_ca_req.pem \
        -pkeyopt rsa_keygen_bits:${kl} \
        -passout file:./key_pass.txt \
        -${da} \
        -subj ${ca_subj_req}

    openssl x509 -req \
        -${da} \
        -in temp_ca_req.pem \
        -signkey temp_ca.pem \
        -passin file:./key_pass.txt \
        -out ${ca_cert}.pem \
        -days ${val_period} \
        -extensions v3_ca \
        -extfile ../ca/openssl.cnf
else
    # Generate Elliptic Curve parameters:
    eck='ec-'$cn'.pem'
    openssl ecparam -out $eck -name $cn

    ca_key=./CA1_${da}_${cn}_v3_ca_key
    ca_cert=../crts/CA1_${da}_${cn}_v3_ca_crt
    ca_subj_req=/CN=CA1_${da}_${cn}_v3_ca/
    ca_key_type=ec:${eck}

    openssl req -newkey ${ca_key_type} -passout file:./key_pass.txt \
                -${da} \
                -subj ${ca_subj_req} \
                -x509 -extensions v3_ca \
                -keyout temp_ca.pem \
                -out ${ca_cert}.pem \
                -days ${val_period} -config ../ca/openssl.cnf
fi
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

            srk_subj_req=/CN=SRK${i}_${da}_${kl}_65537_v3_usr/
            srk_crt=../crts/SRK${i}_${da}_${kl}_65537_v3_usr_crt
            srk_key=./SRK${i}_${da}_${kl}_65537_v3_usr_key
        else
            # Generate Elliptic Curve parameters:
            openssl ecparam -out ./temp_srk.pem -name ${cn} -genkey
            # Generate SRK key
            openssl ec -in ./temp_srk.pem -des3 -passout file:./key_pass.txt \
                       -out ./temp_srk.pem

            srk_subj_req=/CN=SRK${i}_${da}_${cn}_v3_usr/
            srk_crt=../crts/SRK${i}_${da}_${cn}_v3_usr_crt
            srk_key=./SRK${i}_${da}_${cn}_v3_usr_key
        fi

        # Generate SRK certificate signing request
        openssl req -new -batch -passin file:./key_pass.txt \
                    -subj ${srk_subj_req} \
                    -key ./temp_srk.pem \
                    -out ./temp_srk_req.pem

        # Generate SRK certificate (this is a CA cert)
           openssl ca -batch -passin file:./key_pass.txt \
                      -md ${da} -outdir ./ \
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
        echo rsa algorithm = $rsa_algo
            # Generate SRK key
            openssl genpkey -algorithm ${rsa_algo} -pkeyopt rsa_keygen_bits:${kl} \
                            -pass file:./key_pass.txt \
                            -out ./temp_srk.pem

            srk_subj_req=/CN=SRK${i}_${da}_${kl}_65537_v3_ca/
            srk_crt=../crts/SRK${i}_${da}_${kl}_65537_v3_ca_crt
            srk_key=./SRK${i}_${da}_${kl}_65537_v3_ca_key
        else
            # Generate Elliptic Curve parameters:
            openssl ecparam -out ./temp_srk.pem -name ${cn} -genkey
            # Generate SRK key
            openssl ec -in ./temp_srk.pem -des3 -passout file:./key_pass.txt \
                       -out ./temp_srk.pem

            srk_subj_req=/CN=SRK${i}_${da}_${cn}_v3_ca/
            srk_crt=../crts/SRK${i}_${da}_${cn}_v3_ca_crt
            srk_key=./SRK${i}_${da}_${cn}_v3_ca_key
    fi
    # Generate SRK certificate signing request
       openssl req -new -batch -passin file:./key_pass.txt \
                   -subj ${srk_subj_req} \
                   -key ./temp_srk.pem \
                   -out ./temp_srk_req.pem

    # Generate SRK certificate (this is a CA cert)
       openssl ca -batch -passin file:./key_pass.txt \
                  -md ${da} -outdir ./ \
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
    echo + Generating SGK key and certificate $i +
    echo ++++++++++++++++++++++++++++++++++++++++
    echo

    if [ $use_ecc = 'n' ]
        then
            srk_crt_i=../crts/SRK${i}_${da}_${kl}_65537_v3_ca_crt.pem
            srk_key_i=./SRK${i}_${da}_${kl}_65537_v3_ca_key.pem
            # Generate key
            openssl genpkey -algorithm ${rsa_algo} -pkeyopt rsa_keygen_bits:${kl} \
                            -pass file:./key_pass.txt \
                            -out ./temp_sgk.pem

            sgk_subj_req=/CN=SGK${i}_1_${da}_${kl}_65537_v3_usr/
            sgk_crt=../crts/SGK${i}_1_${da}_${kl}_65537_v3_usr_crt
            sgk_key=./SGK${i}_1_${da}_${kl}_65537_v3_usr_key
        else
            srk_crt_i=../crts/SRK${i}_${da}_${cn}_v3_ca_crt.pem
            srk_key_i=./SRK${i}_${da}_${cn}_v3_ca_key.pem
            # Generate Elliptic Curve parameters:
            openssl ecparam -out ./temp_sgk.pem -name ${cn} -genkey
            # Generate key
            openssl ec -in ./temp_sgk.pem -des3 -passout file:./key_pass.txt \
                       -out ./temp_sgk.pem

            sgk_subj_req=/CN=SGK${i}_1_${da}_${cn}_v3_usr/
            sgk_crt=../crts/SGK${i}_1_${da}_${cn}_v3_usr_crt
            sgk_key=./SGK${i}_1_${da}_${cn}_v3_usr_key
    fi

    # Generate SGK certificate signing request
    openssl req -new -batch -passin file:./key_pass.txt \
                -subj ${sgk_subj_req} \
                -key ./temp_sgk.pem \
                -out ./temp_sgk_req.pem

    # Generate SGK certificate (this is a user cert)
    openssl ca -batch -md ${da} -outdir ./ \
               -passin file:./key_pass.txt \
               -in ./temp_sgk_req.pem \
               -cert ${srk_crt_i} \
               -keyfile ${srk_key_i} \
               -extfile ../ca/v3_usr.cnf \
               -out ${sgk_crt}.pem \
               -days ${val_period} \
               -config ../ca/openssl.cnf

    # Convert SGK Certificate to DER format
    openssl x509 -inform PEM -outform DER \
                 -in ${sgk_crt}.pem \
                 -out ${sgk_crt}.der

    # Generate SGK key in PKCS #8 format - both PEM and DER
    openssl pkcs8 -passin file:./key_pass.txt -passout file:./key_pass.txt \
                  -topk8 -inform PEM -outform DER -v2 des3 \
                  -in temp_sgk.pem \
                  -out ${sgk_key}.der

    openssl pkcs8 -passin file:./key_pass.txt -passout file:./key_pass.txt \
                  -topk8 -inform PEM -outform PEM -v2 des3 \
                  -in temp_sgk.pem \
                  -out ${sgk_key}.pem

    # Cleanup
    \rm ./temp_sgk.pem ./temp_sgk_req.pem

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
