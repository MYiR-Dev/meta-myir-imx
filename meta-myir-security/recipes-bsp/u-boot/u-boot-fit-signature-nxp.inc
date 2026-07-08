# u-boot-fit-signature-nxp.inc
# concat_dtb() hooks for NXP i.MX6ULL u-boot.imx format.
#
# Problem: concat_dtb() from uboot-sign.bbclass doesn't know how to
# handle the u-boot.imx format:
#   1. make u-boot.imx may not generate u-boot.dtb separately
#   2. concat_dtb() overwrites u-boot.imx with raw binary (cat)
#
# Solution:
#   concat_dtb:prepend  -> force u-boot.dtb generation
#   concat_dtb:append   -> rebuild u-boot.imx (EXT_DTB), re-HAB-sign
#
# Guard: all hooks are scoped to mx6ull-generic-bsp to ensure
# zero impact on i.MX95 (mx9-generic-bsp) builds.

concat_dtb_pre_nxp() {
    # Force generation of u-boot.dtb for FIT key embedding.
    # make u-boot.imx on NXP BSP may skip building u-boot.dtb as a
    # separate artifact (it's embedded in the .imx container directly).
    if [ "$2" != "u-boot.imx" ]; then
        bbfatal "FIT: don't know how to handle bootloader binary '$2' other than u-boot.imx"
    fi
    bbdebug 1 "FIT: generating ${UBOOT_DTB_BINARY} for FIT key embedding"
    oe_runmake ${UBOOT_DTB_BINARY}
}

concat_dtb_post_nxp() {
    # concat_dtb() overwrites u-boot.imx with raw binary
    # (cat u-boot-nodtb.bin + u-boot.dtb-signed).
    # Rebuild u-boot.imx with the signed DTB, then re-apply HAB signature.
    if [ "$2" != "u-boot.imx" ]; then
        bbfatal "FIT: don't know how to handle bootloader binary '$2' other than u-boot.imx"
    fi
    if [ ! -e "${UBOOT_DTB_SIGNED}" ]; then
        bbwarn "FIT: ${UBOOT_DTB_SIGNED} not found, skipping u-boot.imx rebuild"
        return 0
    fi

    bbnote "FIT: rebuilding u-boot.imx with signed DTB"
    rm -f u-boot.imx u-boot.imx.log
    oe_runmake EXT_DTB="${UBOOT_DTB_SIGNED}" u-boot.imx

    bbnote "FIT: re-HAB-signing rebuilt u-boot.imx"
    myir_imx6_imx7_sign_habv4 "IMX6ULL" "${type}" "${binary}"
}

concat_dtb:prepend:mx6ull-generic-bsp() {
    if [ "${MYIR_FIT_ENABLE}" = "1" ]; then
        concat_dtb_pre_nxp "$@"
    fi
}

concat_dtb:append:mx6ull-generic-bsp() {
    if [ "${MYIR_FIT_ENABLE}" = "1" ]; then
        concat_dtb_post_nxp "$@"
    fi
}
