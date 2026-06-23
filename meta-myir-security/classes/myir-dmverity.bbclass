# myir-dmverity.bbclass — Minimal NXP-style dm-verity class
#
# All dm-verity configuration lives in local.conf (NXP approach).
# This class only handles what cannot be expressed as a variable:
#   1. Deterministic verity salt
#   2. Enables dm-verity + root hash signing classes

# Deterministic salt -> reproducible root hash across build passes
DM_VERITY_SALT_INPUT ?= "${MACHINE}-myir-dmverity-v2"
DM_VERITY_SETUP_ARGS = "${@'--salt=' + __import__('hashlib').sha256((d.getVar('DM_VERITY_SALT_INPUT') or '').encode('utf-8')).hexdigest()}"

# Enable dm-verity image generation
IMAGE_CLASSES += "dm-verity-img"

# Root hash RSA signing + MYIR overlay/env injection
# dm-verity-verify-roothash.bbclass overrides process_verity() from
# dm-verity-img.bbclass to inject MYIR flags before the SEPARATE_HASH return.
IMAGE_CLASSES += "dm-verity-verify-roothash"

DISTROOVERRIDES .= ":myir-dmverity"

WKS_FILE:myir-dmverity = "myd-jmx95-15x15-lpddr5-dmverity-overlay.wks.in"

# ==========================================================================
# Single-pass build fix (only active when ENABLE_DM_VERITY=1 → this class loads)
# dm-verity creates: rootfs:do_rootfs → imx-boot → kernel → initramfs → rootfs
# Remove boot deps from WKS_FILE_DEPENDS (which feeds rootfs DEPENDS),
# add them to do_image_wic[depends] instead — do_image_wic runs LAST.
# ==========================================================================
WKS_FILE_DEPENDS:remove = "virtual/bootloader imx-boot"
do_image_wic[depends] += "imx-boot:do_deploy virtual/bootloader:do_deploy"

# ==========================================================================
# Kernel container signing is for OS container mode (sec_boot only).
# dm-verity uses fitImage for kernel integrity — skip container signing.
# = is strong assignment; beats the ?= in myir-kernel-container-sign.bbclass.
# ==========================================================================
MYIR_KERNEL_CONTAINER_ENABLE = "0"

# Remove OS container files from IMAGE_BOOT_FILES — dm-verity uses fitImage for
# kernel integrity, so os_cntr_signed*.bin (kernel AHAB container) is not needed.
# The machine config unconditionally appends them when sec_boot is in DISTRO_FEATURES.
#IMAGE_BOOT_FILES:remove = "os_cntr_signed.bin os_cntr_signed_4k-lt9611-lvds1-ov5640.bin os_cntr_signed_dsi-mipi101c.bin os_cntr_signed_lt9611-lvds1-ov5640.bin os_cntr_signed_lvds0-lvds1-ov5640.bin os_cntr_signed_lvds-dual.bin"

# ==========================================================================
# Deploy AHAB-signed boot container for WIC (replaces the container-sign
# do_deploy:append which is gated on MYIR_KERNEL_CONTAINER_ENABLE=1).
#
# Uses Python postfuncs instead of shell do_deploy:append to avoid
# shell syntax bugs in BitBake's generated run.do_deploy script.
# PN check ensures this only runs for imx-boot, not linux-imx etc.
# ==========================================================================
python deploy_ahabsigned_mx95() {
    import os
    import shutil
    import glob

    # Only active for imx-boot recipe
    if d.getVar('PN') != 'imx-boot':
        return

    deploydir = d.getVar('DEPLOYDIR')
    srcdir = d.getVar('S')
    machine = d.getVar('MACHINE')
    workdir = d.getVar('WORKDIR')

    bb.note("myir-dmverity: deploying AHAB-signed boot container")

    # Deploy signed boot binaries from S (imx-mkimage staging dir)
    pattern = os.path.join(srcdir, 'imx-boot*-%s*.signed' % machine)
    for signed_boot in glob.glob(pattern):
        if os.path.isfile(signed_boot):
            dest = os.path.join(deploydir, os.path.basename(signed_boot))
            shutil.copy2(signed_boot, dest)
            bb.note("  Deployed: %s" % os.path.basename(signed_boot))

    # Create imx-boot-signed symlink
    imx_boot_signed = os.path.join(deploydir, 'imx-boot-signed')
    if not os.path.exists(imx_boot_signed):
        imx_boot = os.path.join(deploydir, 'imx-boot')
        if os.path.islink(imx_boot):
            target = os.readlink(imx_boot)
            signed_file = target + '.signed'
            signed_path = os.path.join(deploydir, signed_file)
            if os.path.exists(signed_path):
                os.symlink(signed_file, imx_boot_signed)
                bb.note("  Created imx-boot-signed -> %s" % signed_file)

    # Deploy fuse-cmds.txt
    fuse_src = os.path.join(workdir, 'fuse-cmds.txt')
    if os.path.exists(fuse_src):
        shutil.copy2(fuse_src, os.path.join(deploydir, 'fuse-cmds.txt'))
        bb.note("  Deployed: fuse-cmds.txt")
}

do_deploy[postfuncs] += "deploy_ahabsigned_mx95"
