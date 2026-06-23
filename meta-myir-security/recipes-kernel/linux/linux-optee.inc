# linux-optee.inc
# Kernel OP-TEE configuration include for MYIR i.MX95
#
# When MYIR_OPTEE_STORAGE=rpmb, loads optee.cfg + tee.cfg + rpmb.cfg
#
# rpmb.cfg enables kernel RPMB subsystem so OP-TEE RPMB-FS uses
# in-kernel routing (rpmb_routing_model=kernel) instead of relying
# on tee-supplicant (NXP 4.8 does not support new RPMB probe protocol).

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

python __anonymous() {
    storage = d.getVar("MYIR_OPTEE_STORAGE")
    if storage == "rpmb":
        # OP-TEE kernel driver
        d.appendVar("SRC_URI", " file://optee.cfg")
        d.appendVar("DELTA_KERNEL_DEFCONFIG", " optee.cfg")

        # Trusted Keys via TEE
        d.appendVar("SRC_URI", " file://tee.cfg")
        d.appendVar("DELTA_KERNEL_DEFCONFIG", " tee.cfg")

        # RPMB subsystem - critical: enables in-kernel RPMB routing
        d.appendVar("SRC_URI", " file://rpmb.cfg")
        d.appendVar("DELTA_KERNEL_DEFCONFIG", " rpmb.cfg")

        bb.debug(1, "OP-TEE RPMB-FS: optee.cfg + tee.cfg + rpmb.cfg added")
}
