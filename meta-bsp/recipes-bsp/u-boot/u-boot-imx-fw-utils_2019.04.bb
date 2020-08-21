require recipes-bsp/u-boot/u-boot-fw-utils_2019.07.bb

require u-boot-common.inc

#SRC_URI = "git://${FSL_ARM_GIT_SERVER}/imx/uboot-imx.git;branch=imx_v2019.04;protocol=ssh"
#SRCREV = "f0238679d332f1af2148d467804a93de8f868bd5"

inherit fsl-u-boot-localversion

LOCALVERSION ?= "-${SRCBRANCH}"
