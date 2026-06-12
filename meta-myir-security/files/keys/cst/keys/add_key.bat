@echo off

::-----------------------------------------------------------------------------
::
:: File: add_key.bat
::
:: Description: This script adds a key to an existing HAB PKI tree to be used
::              with the HAB code signing feature.  Both the private key and
::              corresponding certificate are generated.  This script can
::              generate new SRKs, CSF keys and Images keys for HAB4 or AHAB.
::              This script is not intended for generating CA root keys.
::
::            (c) Freescale Semiconductor, Inc. 2011. All rights reserved.
::            Copyright 2018-2022 NXP
::
::
::-----------------------------------------------------------------------------

set scriptName=%0
set scriptPath=%~dp0
set numArgs=0
for %%x in (%*) do set /A numArgs+=1

if %numArgs% GTR 0 (
	set interactive=n
) else (
	set interactive=y
)

set max_param=20
set min_param=16

if %interactive%==n (
	if "%1" == "-h" ( goto usage )
	if "%1" == "--help" ( goto usage )
) else (
	goto version
)

:: Validate command line parameters
if %numArgs% LSS %min_param% (
	echo ERROR: Correct parameters required in non-interactive mode
	goto usage
)
if %numArgs% GTR %max_param% (
	echo ERROR: Correct parameters required in non-interactive mode
	goto usage
)

:: Process command line inputs
set args=0
set "ver="
set "key_name="
set "kt="
set "kl="
set "md="
set "duration="
set "srk="
set "srk_ca="
set "signing_key="
set "signing_crt="

:PROCESSINPUT
if %args% GEQ %numArgs% goto validateargs
if "%1"=="-ver" (
	set ver=%2
	goto shiftargs
)
if "%1"=="-key-name" (
	set key_name=%2
	goto shiftargs
)
if "%1"=="-kt" (
	set kt=%2
	goto shiftargs
)
if "%1"=="-kl" (
	set kl=%2
	goto shiftargs
)
if "%1"=="-md" (
	set md=%2
	goto shiftargs
)
if "%1"=="-duration" (
	set duration=%2
	goto shiftargs
)
if "%1"=="-srk" (
	set srk=%2
	goto shiftargs
)
if "%1"=="-srk-ca" (
	set srk_ca=%2
	goto shiftargs
)
if "%1"=="-signing-key" (
	set signing_key=%2
	goto shiftargs
)
if "%1"=="-signing-crt" (
	set signing_crt=%2
	goto shiftargs
) else (
	echo ERROR: Invalid parameter: %1
    goto usage
)

:SHIFTARGS
shift
shift
set /A args+=2
goto processinput

:VALIDATEARGS
if defined md ( if %ver%==4 (
	echo ERROR: Message digest is fixed for HAB4
	goto usage
))

if %srk%==y ( if not defined srk_ca (
	echo ERROR: SRK CA option required when SRK is selected
	goto usage
))

goto version

:USAGE
echo.
echo Usage:"
echo Interactive Mode:"
echo %scriptName%
echo.
echo Command Line Mode:"
echo "%scriptName% -ver <4/a> -key-name <new key name> -kt <ecc/rsa/rsa-pss> -kl <key length> [-md <message digest>] -duration <years> -srk <y/n> [-srk-ca <y/n>] -signing-key <CA/SRK signing key> -signing-crt <CA/SRK signing cert>"
echo Options:"
echo     -kl: -kt = ecc then Supported key lengths: p256, p384, p521
echo        : -kt = rsa then Supported key lengths: 1024, 2048, 3072, 4096
echo        : -kt = rsa-pss then Supported key lengths: 1024, 2048, 3072, 4096
echo     -md: -ver = a then Supported message digests: sha256, sha384, sha512
echo        : -ver = 4 then md = sha256 is fixed
echo.
echo "%scriptName% -h | --help : This text"
echo.
exit /B

:VERSION
if %interactive%==y (
	set /P ver="Which version of HAB do you want to generate the key for (4 = HAB4 / a = AHAB)?: "
)
if %ver%==4 goto VALID_ver
if %ver%==a goto VALID_ver
echo Error - HAB version selected must be either 3, 4 or a
exit /B
:VALID_ver

if %interactive%==y (
	set /P key_name="Enter new key name (e.g. SRK5): "
)

:: Key type
:: AHAB or HAB4
if %interactive%==y (
	set /P kt="Enter new key type (ecc / rsa / rsa-pss): "
)
:: Confirm that a valid key type has been entered
if %kt%==ecc goto KEY_TYPE_DONE
if %kt%==rsa set rsa_algo=rsa & goto KEY_TYPE_DONE
if %kt%==rsa-pss set rsa_algo=rsa-pss & goto KEY_TYPE_DONE
echo Invalid key type. Supported key types: rsa, ecc
exit /B
:KEY_TYPE_DONE

:: Key length
if %kt%==ecc goto KEY_LENGTH_ECC
:: RSA
if %interactive%==y (
	set /P kl="Enter new key length in bits: "
)
:: Confirm that a valid key length has been entered
if %kl%==2048 goto VALID_KEY_LENGTH
if %kl%==3072 goto VALID_KEY_LENGTH
if %kl%==4096 goto VALID_KEY_LENGTH
echo Invalid key length. Supported key lengths: 2048, 3072, 4096
exit /B

:KEY_LENGTH_ECC
:: ECC
if %interactive%==y (
	set /P kl="Enter new key length (p256 / p384 / p521): "
)
:: Confirm that a valid key length has been entered
if %kl%==p256 set "cn=secp256r1"  & goto VALID_KEY_LENGTH
if %kl%==p384 set "cn=secp384r1"  & goto VALID_KEY_LENGTH
if %kl%==p521 set "cn=secp521r1"  & goto VALID_KEY_LENGTH
echo Invalid key length. Supported key lengths: 256, 384, 521
exit /B
:VALID_KEY_LENGTH

:: Message digest
if not %ver%==a goto MD_DEFAULT
:: AHAB
if %interactive%==y (
	set /P md="Enter new message digest (sha256, sha384, sha512): "
)
:: Confirm that a valid message digest has been entered
if %md%==sha256 goto MD_DONE
if %md%==sha384 goto MD_DONE
if %md%==sha512 goto MD_DONE
echo Invalid message digest. Supported message digests: sha256, sha384, sha512
exit /B
:: HAB4
:MD_DEFAULT
set md=sha256
:MD_DONE

if %interactive%==y (
	set /P duration="Enter certificate duration (years): "
)

:: Compute validity period
set /A val_period=%duration%*365

:: ---------------- Add SRK key and certificate -------------------
if %interactive%==y (
	set /P srk="Is this an SRK key? "
)
if %srk%==n goto GEN_CSF_IMG_SGK

:: Check if SRKs should be generated as CA certs or user certs
if %ver%==3 goto CA_DEFAULT
if %interactive%==y (
	set /P srk_ca="Do you want the SRK to have the CA flag set (y/n)?: "
)
if %srk_ca%==y goto CA_DEFAULT
set ca=usr
goto CA_DONE
:CA_DEFAULT
set ca=ca
:CA_DONE

if %interactive%==y (
	set /P signing_key="Enter CA signing key name: "
	set /P signing_crt="Enter CA signing certificate name: "
)
goto BEFORE_GEN_KEYS

:GEN_CSF_IMG_SGK
if %ver%==a goto GEN_SGK

:: ---------------- Add CSF/IMG key and certificate -------------------
set ca=usr
if %interactive%==y (
	set /P signing_key="Enter SRK signing key name: "
	set /P signing_crt="Enter SRK signing certificate name: "
)
goto BEFORE_GEN_KEYS

:GEN_SGK
:: ---------------- Add SGK key and certificate -------------------
set ca="usr"
set /P signing_key="Enter SRK signing key name: "
set /P signing_crt="Enter SRK signing certificate name: "
goto BEFORE_GEN_KEYS

:BEFORE_GEN_KEYS
:: Check existance of keys/, crts/ and ca/ directories of <cst> before generating keys and
:: switch current working directory to <cst>/keys directory, if needed.
set crt_dir=%cd%
set keys_dir=%scriptPath%\\..\\keys\\
set crts_dir=%scriptPath%\\..\\crts\\
set ca_dir=%scriptPath%\\..\\ca\\

if not exist "%keys_dir%" (
    echo ERROR: Private keys directory %keys_dir% is missing. Expecting script to be located inside ^<cst^>/keys directory.
    exit /B
)

if not exist "%crts_dir%" (
    echo ERROR: Public keys directory %crts_dir% is missing. Expecting ^<cst^>/crts directory to be already created.
    exit /B
)

if not exist "%ca_dir%" (
    echo ERROR: Openssl configuration directory %ca_dir% is missing. Expecting ^<cst^>/ca directory to hold openssl configuration files.
    exit /B
)

:: Switch current working directory to <cst>/keys directory, if needed.
if not "%crt_dir%" == "%keys_dir%" (
    cd "%keys_dir%" 
    if %errorlevel% NEQ 0 (
        echo ERROR: Cannot change directory to %keys_dir%
        exit /B
    )
)

:OPENSSL_INIT
:: The following is required otherwise OpenSSL complains
set OPENSSL_CONF=..\\ca\\openssl.cnf

:GEN_OUTPUTS
:: ---------------- Generate outputs ------------------------------

:: Generate key
if %kt%==rsa goto GEN_KEY_RSA
if %kt%==rsa-pss goto GEN_KEY_RSA
set key_fullname=%key_name%_%md%_%cn%_v3_%ca%
:: Generate Elliptic Curve parameters
openssl ecparam -out %key_fullname%_key.pem -name %cn% -genkey
:: Generate ECC key
openssl ec -in %key_fullname%_key.pem -des3 -passout file:key_pass.txt ^
    -out %key_fullname%_key.pem
goto GEN_KEY_DONE
:GEN_KEY_RSA
set key_fullname=%key_name%_%md%_%kl%_65537_v3_%ca%
:: Generate RSA key
openssl genpkey -algorithm %rsa_algo% -pkeyopt rsa_keygen_bits:%kl% ^
    -pass file:key_pass.txt ^
    -out %key_fullname%_key.pem
:GEN_KEY_DONE

:: Generate certificate signing request
openssl req -new -batch -passin file:key_pass.txt ^
    -subj /CN=%key_fullname%/ ^
    -key %key_fullname%_key.pem ^
    -out %key_fullname%_req.pem

:: Generate certificate
openssl ca -batch -passin file:key_pass.txt ^
    -md %md% -outdir . ^
    -in %key_fullname%_req.pem ^
    -cert %signing_crt% ^
    -keyfile %signing_key% ^
    -extfile ..\\ca\\v3_%ca%.cnf ^
    -out ..\\crts\\%key_fullname%_crt.pem ^
    -days %val_period% ^
    -config ..\\ca\\openssl.cnf

:: Convert certificate to DER format
openssl x509 -inform PEM -outform DER ^
    -in ..\\crts\\%key_fullname%_crt.pem ^
    -out ..\\crts\\%key_fullname%_crt.der

:: Generate key in PKCS #8 format - both PEM and DER
openssl pkcs8 -passin file:key_pass.txt ^
    -passout file:key_pass.txt ^
    -topk8 -inform PEM -outform DER -v2 des3 ^
    -in %key_fullname%_key.pem ^
    -out %key_fullname%_key.der

openssl pkcs8 -passin file:key_pass.txt ^
    -passout file:key_pass.txt ^
    -topk8 -inform PEM -outform PEM -v2 des3 ^
    -in %key_fullname%_key.pem ^
    -out %key_fullname%_key_tmp.pem

del /F %key_fullname%_key.pem
ren %key_fullname%_key_tmp.pem %key_fullname%_key.pem

:CLEAN
:: Clean up
del /F *_req.pem

:DONE
:: Switch back to initial working directory, if needed.
if not "%crt_dir%" == "%keys_dir%" (
    cd "%crt_dir%" 
    if %errorlevel% NEQ 0 (
        echo ERROR: Cannot change directory to %crt_dir%
        exit /B
    )
)
exit /B
