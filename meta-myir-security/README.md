# meta-myir-security - i.MX95 AHAB Secure Boot Layer

## Overview

This Yocto layer adds AHAB (Advanced High Assurance Boot) secure boot support for MYIR i.MX95 platforms. It integrates NXP's CST (Code Signing Tool) into the Yocto build flow to produce signed `flash.bin` images.

## Architecture

```
imx-mkimage (generates flash.bin)
    |
    v
do_compile: flash.bin built (unsigned AHAB container)
    |
    v
do_ahab_sign: CST signs flash.bin with AHAB CSF
    |           - myir-ahab.bbclass generates CSF from template
    |           - CST validates and signs the container
    v
do_install/do_deploy: signed flash.bin deployed
```

### i.MX95 AHAB vs i.MX8 HABv4

| Feature | i.MX8 HABv4 | i.MX95 AHAB |
|---------|-------------|-------------|
| Container | HABv4 IVT | AHAB Container v2.0 |
| Enclave | SECO | ELE (EdgeLock Enclave) |
| Key minimum | RSA 2048 / ECC p256 | ECC secp384r1 |
| Signature | Per-image IVT | Container-level |
| Tool | CST v3.1+ | CST v3.3.0+ or SPSDK |
| PQC support | No | Yes (ML-DSA-65) |

## Quick Start

### 1. Download CST Tool

NXP CST v3.3.0+ required for i.MX9 AHAB support:
https://www.nxp.com/webapp/sps/download/license.jsp?colCode=IMX_CST_TOOL_NEW

### 2. Generate Keys

```bash
export CST_DIR=/path/to/your/cst
cd sources/meta-myir-security/recipes-bsp/imx-fuses/files/
./gen_keys.sh
```

Output files:
- `$CST_DIR/crts/SRK_1_2_3_4_tables.bin` - SRK table (fused to SoC)
- `$CST_DIR/crts/SRK_1_2_3_4_fuses.bin` - SRK fuse values
- `$CST_DIR/keys/SRK*_key.pem` - SRK private key (KEEP SAFE!)

### 3. Configure Build

Add to `conf/local.conf`:

```
MYIR_AHAB_ENABLE = "1"
MYIR_CST_DIR = "/path/to/your/cst"
```

### 4. Build

```bash
DISTRO=fsl-imx-xwayland MACHINE=myd-jmx95-15x15-lpddr5 source myir-setup-release.sh -b build-xwayland
bitbake imx-boot
```

### 5. Burn Fuses (IRREVERSIBLE!)

```bash
./gen_fuse_cmds.sh   # Generate U-Boot fuse commands
```

In U-Boot console, paste each fuse command, verify, then:
```
u-boot=> ahab_close    # Final irreversible step!
```

## Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| MYIR_AHAB_ENABLE | 0 | Set to 1 to enable AHAB signing |
| MYIR_CST_DIR | ${TOPDIR}/keys/cst | CST installation path |
| MYIR_AHAB_KEY_TYPE | ecc | Key type |
| MYIR_AHAB_KEY_CURVE | secp384r1 | ECC curve |
| MYIR_AHAB_DIGEST | sha384 | Digest algorithm |
| MYIR_AHAB_SRK_INDEX | 1 | SRK index (1-4) |
| MYIR_AHAB_USE_SGK | 0 | Use subordinate SGK key |

## Layer Files

```
meta-myir-security/
  conf/layer.conf                       - Layer configuration
  classes/myir-ahab.bbclass             - AHAB signing class
  recipes-bsp/imx-mkimage/
    files/mx95_ahab.csf.template        - i.MX95 AHAB CSF template
    imx-boot_1.0.bbappend               - imx-boot integration
  recipes-bsp/imx-fuses/
    files/gen_keys.sh                   - Key generation script
    files/gen_fuse_cmds.sh              - Fuse command generator
    myir-fuse-tools_1.0.bb              - Fuse tools recipe
  README.md                             - This file
```

## Security Notes

- Private keys in `keys/` must be stored securely
- SRK fuses are one-time programmable - cannot be reverted
- `ahab_close` is irreversible - test thoroughly before closing
- Without the private key, signed updates are impossible
- For production, use an HSM for key storage

## Troubleshooting

**CST signing fails: "Container not found"**
- Verify offsets in CSF template match imx-mkimage output
- For i.MX95 defaults: container=0x400, signature=0x590

**CST signing fails: "SRK table not found"**
- Run gen_keys.sh first
- Verify $CST_DIR/crts/SRK_1_2_3_4_tables.bin exists

**Build fails: "AHAB signing skipped"**
- Verify MYIR_AHAB_ENABLE = "1" in local.conf
- Verify machine is mx95 family

## References

- i.MX95 Security Reference Manual (SRM)
- NXP AN12912: i.MX9 Secure Boot Guide
- NXP CST User Guide
- SPSDK: https://github.com/nxp-mcuxpresso/spsdk
