# optee-os_%.imx.bbappend
# MYIR Security Layer - OP-TEE OS RPMB-FS support
#
# 条件引入 RPMB-FS 配置.
# 不设置 MYIR_OPTEE_STORAGE 时默认使用 REE-FS (NXP 原始行为).
#
# 设置方式 (local.conf):
#   MYIR_OPTEE_STORAGE = "rpmb"
#   MYIR_RPMB_MODE = "test"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

require ${@oe.utils.conditional('MYIR_OPTEE_STORAGE', 'rpmb', 'optee-os-rpmb-fs.inc', '', d)}
