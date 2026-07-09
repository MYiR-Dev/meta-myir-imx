require recipes-security/optee/optee-examples.inc
COMPATIBLE_MACHINE = "${@bb.utils.contains('MACHINE_FEATURES', 'optee', '(mx9-nxp-bsp|mx6ull-nxp-bsp)', '(mx9-nxp-bsp)', d)}"
# v4.8.0
SRCREV = "378dc0db2d5dd279f58a3b6cb3f78ffd6b165035"
