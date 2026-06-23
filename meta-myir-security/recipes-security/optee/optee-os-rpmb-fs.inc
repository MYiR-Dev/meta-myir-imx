# optee-os-rpmb-fs.inc
# RPMB-FS (Replay Protected Memory Block - File System) 安全存储配置
#
# 通过 MYIR_OPTEE_STORAGE 和 MYIR_RPMB_MODE 控制 REE-FS 与 RPMB-FS 的切换
#
# 使用方式 (在 local.conf 或 machine.conf 中设置):
#
#   1. REE-FS (默认):
#      MYIR_OPTEE_STORAGE = "ree"
#
#   2. RPMB-FS 软件模拟 (开发测试, 重启丢失):
#      MYIR_OPTEE_STORAGE = "rpmb"
#      MYIR_RPMB_MODE = "emu"
#
#   3. RPMB-FS 真实 eMMC + 测试密钥 (开发验证):
#      MYIR_OPTEE_STORAGE = "rpmb"
#      MYIR_RPMB_MODE = "test"
#
#   4. RPMB-FS 真实 eMMC + 烧录密钥 (工厂一次性操作):
#      MYIR_OPTEE_STORAGE = "rpmb"
#      MYIR_RPMB_MODE = "provision"
#
#   5. RPMB-FS 真实 eMMC (生产模式, 密钥已预烧录):
#      MYIR_OPTEE_STORAGE = "rpmb"
#      MYIR_RPMB_MODE = "prod"
#

# ---- 默认值 ----
MYIR_OPTEE_STORAGE ?= "ree"
MYIR_RPMB_MODE ?= "emu"

# ---- eMMC 设备 ID (i.MX95 通常为 0) ----
MYIR_RPMB_FS_DEV_ID ?= "0"

# ---- RPMB 模拟标志: emu 模式为 1, 其余为 0 ----
RPMB_EMU = "${@'1' if d.getVar('MYIR_RPMB_MODE') == 'emu' else '0'}"

# ===================================================================
# RPMB-FS 条件编译 (当 MYIR_OPTEE_STORAGE = "rpmb" 时生效)
# ===================================================================

# NXP 下游 Makefile 构建体系 (optee-os_%.imx.bb)
# 核心: CFG_RPMB_FS=y + CFG_REE_FS=n 实现 RPMB 安全存储
RPMB_FS_OEMAKE = " \
    RPMB_EMU=${RPMB_EMU} \
    CFG_REE_FS=n \
    CFG_RPMB_FS=y \
    CFG_RPMB_FS_DEV_ID=${MYIR_RPMB_FS_DEV_ID} \
    CFG_CORE_DYN_SHM=y \
    CFG_SCTLR_ALIGNMENT_CHECK=n \
    CFG_PREALLOC_RPC_CACHE=n \
    CFG_CORE_HEAP_SIZE=2097152 \
    CFG_TEE_RAM_VA_SIZE=4194304 \
"

EXTRA_OEMAKE:append = " ${@oe.utils.conditional('MYIR_OPTEE_STORAGE', 'rpmb', '${RPMB_FS_OEMAKE}', '', d)}"

# ===================================================================
# RPMB 模式选择
# ===================================================================

# --- 模式: emu (软件模拟 RPMB, 无需真实 eMMC RPMB 分区) ---
EXTRA_OEMAKE:append = " \
    ${@oe.utils.conditional('MYIR_RPMB_MODE', 'emu', \
        'CFG_RPMB_EMU=y CFG_RPMB_TESTKEY=y', \
        '', d)} \
"

# --- 模式: test (真实 eMMC + 测试密钥) ---
EXTRA_OEMAKE:append = " \
    ${@oe.utils.conditional('MYIR_RPMB_MODE', 'test', \
        'CFG_RPMB_EMU=n CFG_RPMB_TESTKEY=y', \
        '', d)} \
"

# --- 模式: provision (工厂烧录 RPMB 密钥, 一次性操作) ---
# CFG_RPMB_WRITE_KEY=y: 将 RPMB 认证密钥写入 eMMC 的安全区域
# CFG_RPMB_RESET_FAT=y: 重置 RPMB FAT 表
EXTRA_OEMAKE:append = " \
    ${@oe.utils.conditional('MYIR_RPMB_MODE', 'provision', \
        'CFG_RPMB_EMU=n CFG_RPMB_WRITE_KEY=y CFG_RPMB_RESET_FAT=y', \
        '', d)} \
"

# --- 模式: prod (生产模式, 密钥已预烧录) ---
# 不设置 CFG_RPMB_WRITE_KEY 和 CFG_RPMB_TESTKEY
# 密钥通过出厂时的 provision 模式已烧录到 eMMC RPMB 分区
EXTRA_OEMAKE:append = " \
    ${@oe.utils.conditional('MYIR_RPMB_MODE', 'prod', \
        'CFG_RPMB_EMU=n', \
        '', d)} \
"

# ===================================================================
# RPMB 调试日志 (生产模式下关闭)
# ===================================================================
python () {
    storage = d.getVar('MYIR_OPTEE_STORAGE')
    mode = d.getVar('MYIR_RPMB_MODE')

    if storage == 'rpmb':
        bb.plain('=============================================')
        bb.plain(' MYIR OP-TEE Storage: RPMB-FS')
        bb.plain(' RPMB Mode:          %s' % mode)

        mode_desc = {
            'emu':      'Software emulation (reboot loses data)',
            'test':     'Real eMMC with test key',
            'provision': 'FACTORY: Write RPMB key to eMMC (ONE-TIME!)',
            'prod':     'Production mode (key pre-programmed)',
        }
        bb.plain(' Description:        %s' % mode_desc.get(mode, 'Unknown'))
        bb.plain(' RPMB FS Device ID:  %s' % d.getVar('MYIR_RPMB_FS_DEV_ID'))
        bb.plain('=============================================')
    else:
        bb.plain('=============================================')
        bb.plain(' MYIR OP-TEE Storage: REE-FS (default)')
        bb.plain('=============================================')
}
