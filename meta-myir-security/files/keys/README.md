# MYIR Security Keys Directory

## Auto-Setup

The layer.conf event handler (myir_keys_setup_handler) automatically
creates the build-time keys directory at TOPDIR/keys at ConfigParsed time:

  TOPDIR/keys/cst  ->  MYIR_CST_REAL_PATH   (CST tool + AHAB keys/certs)
  TOPDIR/keys/fit  ->  LAYERDIR/files/keys/fit  (FIT signing keys)

No manual setup needed for new builds.

## FIT Keys (files/keys/fit/)

These are DEVELOPMENT keys only. For production keys, run:

  openssl genrsa -F4 -out dev.key 2048
  openssl req -batch -new -x509 -key dev.key -out dev.crt

Then replace the files in this directory.

## AHAB Keys

AHAB keys are stored inside the CST tool installation and are NOT
tracked in git (board-specific, contains private key material).

## Override CST Path

If CST is installed elsewhere, set in local.conf:

  MYIR_CST_REAL_PATH = "/path/to/your/cst-x.x.x"
