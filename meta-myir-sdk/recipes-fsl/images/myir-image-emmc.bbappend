FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

# Install the board-specific CAAM tagged-key stack only in explicitly enabled
# MYD-JS8MPQ images. Other i.MX machines keep their existing package set.
IMAGE_INSTALL:append:myd-js8mpq = "${@' packagegroup-myd-js8mpq-caam-dmcrypt' if d.getVar('MYD_JS8MPQ_CAAM_DMCRYPT') == '1' else ''}"

# Generate the .swu bundle as part of the normal myir-image-emmc build for
# MYD-JS8MPQ A/B images.
IMAGE_CLASSES:append:myd-js8mpq = "${@bb.utils.contains('OTA_SUPPORT', '1', ' swupdate-image', '', d)}"

SWUPDATE_VERSION:myd-js8mpq = "${DISTRO_VERSION}${IMAGE_VERSION_SUFFIX}"
SWUPDATE_IMAGES_FSTYPES[myir-image-emmc] = ".ext4.gz"

# meta-swupdate signs sw-description with the deployed key set. The default
# development key is generated outside the layer. Production builds should
# disable automatic generation and keep keys in a protected external path,
# for example in local.conf or a CI secret configuration:
#
#   SWUPDATE_AUTO_GENERATE_KEYS = "0"
#   SWUPDATE_PRIVATE_KEY = "/secure/path/priv.pem"
#   SWUPDATE_PUBLIC_KEY = "/secure/path/swu_public.pem"
#   SWUPDATE_PASSWORD_FILE = "/secure/path/priv.password"
SWUPDATE_SIGNING:myd-js8mpq = "${@'RSA' if d.getVar('OTA_SUPPORT') == '1' else ''}"

# Generate the development key set before both rootfs construction and SWU
# signing. The public half installed here must match the private key used by
# do_swuimage; otherwise CONFIG_SIGNED_IMAGES devices reject the bundle.
do_rootfs[depends] += "${@'swupdate-signing-keys:do_deploy' if d.getVar('MACHINE') == 'myd-js8mpq' and d.getVar('OTA_SUPPORT') == '1' and d.getVar('SWUPDATE_AUTO_GENERATE_KEYS') == '1' else ''}"
do_swuimage[depends] += "${@'swupdate-signing-keys:do_deploy' if d.getVar('MACHINE') == 'myd-js8mpq' and d.getVar('OTA_SUPPORT') == '1' and d.getVar('SWUPDATE_AUTO_GENERATE_KEYS') == '1' else ''}"

install_swupdate_public_key() {
    if [ "${OTA_SUPPORT}" != "1" ]; then
        return
    fi

    if [ ! -s "${SWUPDATE_PUBLIC_KEY}" ]; then
        bbfatal "SWUpdate public key not found: ${SWUPDATE_PUBLIC_KEY}"
    fi

    install -d "${IMAGE_ROOTFS}${sysconfdir}"
    install -m 0644 "${SWUPDATE_PUBLIC_KEY}" \
        "${IMAGE_ROOTFS}${sysconfdir}/swu_public.pem"
}

ROOTFS_POSTPROCESS_COMMAND:append:myd-js8mpq = " install_swupdate_public_key;"

# The rootfs image is added by swupdate-image. Add the kernel and every DTB
# that can be selected on this board so both boot slots stay equivalent.
SWUPDATE_IMAGES:append:myd-js8mpq = " \
    Image \
    myd-js8mpq.dtb \
    myd-js8mpq-lvds1.dtb \
    myd-js8mpq-lvds-dual.dtb \
    myd-js8mpq-dsi.dtb \
    myd-js8mpq-hdmi-ov5640.dtb \
    myd-js8mpq-hdmi-ov13855-isp.dtb \
    myd-js8mpq-lvds0-lvds1.dtb \
    myd-js8mpq-2g.dtb \
    myd-js8mpq-dsi-2g.dtb \
    myd-js8mpq-lvds1-2g.dtb \
    myd-js8mpq-lvds-dual-2g.dtb \
    myd-js8mpq-hdmi-ov5640-2g.dtb \
    myd-js8mpq-hdmi-ov13855-isp-2g.dtb \
    myd-js8mpq-lvds0-lvds1-2g.dtb \
    myd-js8mpq-hdmi-max96722-2g.dtb \
"
IMAGE_FEATURES:remove:myd-js8mpq = "tools-sdk"

# Hailo：rootfs 使用 runtime，完整开发组放入 SDK
CORE_IMAGE_EXTRA_INSTALL:remove:myd-js8mpq = " \
    packagegroup-hailo-tappas-dev-pkg \
"

CORE_IMAGE_EXTRA_INSTALL:append:myd-js8mpq = " \
    packagegroup-hailo-tappas \
"

TOOLCHAIN_TARGET_TASK:append:myd-js8mpq = " \
    packagegroup-hailo-tappas-dev-pkg \
"
