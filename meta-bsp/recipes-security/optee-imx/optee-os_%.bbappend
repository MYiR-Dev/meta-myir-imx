FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"
SRC_URI += " ${@bb.utils.contains('MACHINENAME', 'myd-jx8mx', 'file://0001-FEAT-myd_jx8mx-imx8mq-2GDDR-configure.patch', '', d)}"