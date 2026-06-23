# optee-client_%.imx.bbappend
# MYIR Security Layer - OP-TEE Client RPMB support
#
# 当使用 RPMB-FS 时:
#   - RPMB_EMU=1: tee-supplicant 用内存模拟 RPMB (开发)
#   - RPMB_EMU=0: tee-supplicant 访问真实 eMMC RPMB 分区 (生产)
#
# tee-supplicant 通过 /dev/mmcblkXrpmb 访问 eMMC RPMB 分区

python () {
    storage = d.getVar("MYIR_OPTEE_STORAGE")
    if storage == "rpmb":
        # 从 MYIR_RPMB_MODE 直接计算 RPMB_EMU
        # （不能读 RPMB_EMU 变量，因为它只在 optee-os-rpmb-fs.inc 中定义，
        #   而该 .inc 不会被 optee-client recipe include）
        mode = d.getVar("MYIR_RPMB_MODE")
        rpmb_emu = "1" if mode == "emu" else "0"

        # tee-supplicant 的 RPMB 模拟标志
        # RPMB_EMU=1: 使用软件模拟 (写入内存/文件)
        # RPMB_EMU=0: 使用真实 eMMC RPMB 分区
        d.appendVar("EXTRA_OECMAKE", " -DRPMB_EMU=" + rpmb_emu)

        bb.plain(" OPTEE Client: RPMB_EMU=%s" % rpmb_emu)
}
