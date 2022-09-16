DESCRIPTION = "pcie driver"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit module 

SRCREV = "0fbe65d59cdaa9c003bf563c1dad366593b8c2b5"
#SRC_URI = "git://github.com/Alex-Hu2020/pcie-driver.git;branch=master 
SRC_URI = "git:///media/wujl/myd-jx8mma7/pcie/pcie-driver;protocol=file;branch=master"
S = "${WORKDIR}/git"

do_compile (){
	oe_runmake 'MODPATH="${base_libdir}/modules/${KERNEL_VERSION}/extra/"'
}

do_install () {
    module_do_install
}

KERNEL_MODULE_AUTOLOAD +="riffa"

#TARGET_CC_ARCH += "${LDFLAGS}"
INSANE_SKIP_${PN}-dev = "ldflags"
INSANE_SKIP_${PN} = "${ERROR_QA} ${WARN_QA}"
